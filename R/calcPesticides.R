#' Calculate pesticide application quantities
#' 
#' This function uses ApplicationRate from SEDAC PEST-CHEMGRIDS rasters and calculates
#' the average quantity of all harmful pesticides used within a buffer of the prison.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param filePath The file path pointing to the unzipped parent SEDAC folder ex.'/ferman-v1-pest-chemgrids-v1-01-geotiff'
#' @param pestTable The .csv file of CalEnviroScreen pesticides created by `getEnviroPest()`
#' @param dist The buffer distance (in meters) to add around prison boundaries
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param writePath If `save = TRUE`, the file path to the folder to save the output csv to
#' 
#' @return The total average pesticide application from 2020 in kg/ha*yr

calcPesticides <- function(prisons, filePath = "data/raw/pesticides/ferman-v1-pest-chemgrids-v1-01-geotiff",
                           pestTable = "data/processed/pesticide_list.csv", dist = 1000, save = TRUE, writePath = 'data/processed/'){
  # Read in SEDAC ApplicationRate .tif(s)
  sedac_filenames <- list.files(path = paste0(filePath,"/ApplicationRate/GEOTIFF"), 
                                pattern = "\\.tif$",
                                full.names = TRUE,
                                no.. = TRUE)
  
  # Create dataframe of SEDAC filenames and associated metadata
  sedac_meta <- data.frame(filename = sedac_filenames, 
                               pest_name = tolower(stringr::word(sedac_filenames, start = 4L, sep = "_")),
                               year = stringr::word(sedac_filenames, start = 5L, sep = "_"))
  
  # Read in converted PDF table
  cal_pest_df <- read_csv(pestTable)
  cal_pest_list <- cal_pest_df$cal_pest_list
  
  ## Filter matching pesticides ----
  pesticide_cal_sedac <- sedac_meta[which(grepl(paste0(cal_pest_list, collapse = '|'), sedac_meta$pest_name)),]
  
  pesticide_cal_sedac_filenames <- pesticide_cal_sedac %>% 
    filter(year == 2020)
  
  # Write to processed files
  write.csv(pesticide_cal_sedac_filenames, "data/processed/pesticide_sedac/pesticides_cal_sedac_filenames.csv")
  
  
  # Calculate usage values (kg/ha-year) from a subset of SEDAC (PEST-CHEMGRIDS). 
  # Usage values (~100ha grid) will then be correlated with prison polygons.
  
  ### GENERATE pesticide AVG files, create SUM spatRaster ----
  
  # Iterating over each pair of pesticide / crop to calculate mean values
  for (index in seq(1, (length(pesticide_cal_sedac_filenames$filename)), 2)) {
    
    # Load the two corresponding High and Low estimate rasters
    rast_H <- terra::rast(pesticide_cal_sedac_filenames$filename[index])
    rast_L <- terra::rast(pesticide_cal_sedac_filenames$filename[index + 1])
    
    # Replace negative values with zero
    rast_H[rast_H < 0] <- 0
    rast_L[rast_L < 0] <- 0
    
    # Create a corresponding filename for export
    stripped_filename <- stringr::word(pesticide_cal_sedac_filenames$filename[index], start = 3L, end = 5L, sep = "_")
    out_filename <- paste0("data/processed/pesticide_sedac/average/", stripped_filename, "_AVG.tif")
    
    # Calculate mean from High and Low estimate
    pesticide_mean <- mosaic(x = rast_H, y = rast_L, fun = "mean", 
                             filename = out_filename, 
                             overwrite = TRUE)
    
  }
  
  ### Collect AVERAGE files
  pest_sedac_files <- list.files("data/processed/pesticide_sedac/average/",
                                 full.names = TRUE,
                                 no.. = TRUE)
  
  pest_collection <- sprc(pest_sedac_files)
  
  # Add overlapping values of pesticides from collection
  pesticide_sum <- mosaic(pest_collection, fun = "sum", 
                          filename = "data/processed/pesticide_sedac/pesticides_sedac_2020.tif", 
                          overwrite = TRUE)
  
  pesticide_sum <- rast("data/processed/pesticide_sedac/pesticides_sedac_2020.tif")
  
  ### Calculate mean usage value for each prison polygon ----
  pesticide_sum_84 <- project(pesticide_sum, prisons)
  
  names(pesticide_sum_84) <- "pesticide_sum_kg_ha.year"
  
  # Extract usage (kg/ha*year) using terra::extract()
  prisons_pest <- prisons %>% 
    mutate(pesticide_use = terra::extract(pesticide_sum_84, prisons, fun = "mean", na.rm = TRUE)) %>% 
    unnest(cols = pesticide_use) %>% 
    select(FACILITYID, pesticides = pesticide_sum_kg_ha.year) %>% 
    st_drop_geometry()
  
  if (save == TRUE) {
    
    write_csv(prisons_pest, paste0(writePath, "/pesticides_", Sys.Date(), ".csv"))
    
  }
  
}

