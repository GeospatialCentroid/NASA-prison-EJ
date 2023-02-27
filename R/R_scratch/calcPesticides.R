# Function to clean filter NASA SEDAC (PEST-CHEMGRIDS) for CalEnviroScreen4.0 Pesticides
# SEDAC dataset: https://sedac.ciesin.columbia.edu/data/set/ferman-v1-pest-chemgrids-v1-01
# CalEnviroScreen list: https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf [Pages 79 - 90]

# File Created: February 15, 2023

library(tidyr)
library(dplyr)
library(tabulizer)
library(terra)
library(sf)
library(leaflet)


calcPesticides <- function(sedac_pesticide_parent){
  # Read in SEDAC ApplicationRate .tif(s)
  sedac_filenames <- list.files(path = paste0(sedac_pesticide_parent,"/ApplicationRate/GEOTIFF"), 
                                pattern = "\\.tif$",
                                full.names = TRUE,
                                no.. = TRUE)
  
  # Create dataframe of SEDAC filenames and associated metadata
  sedac_meta <- data.frame(filename = sedac_filenames, 
                               pest_name = tolower(stringr::word(sedac_filenames, start = 4L, sep = "_")),
                               year = stringr::word(sedac_filenames, start = 5L, sep = "_"))
  
  ## CaliEnviroScreen Pesticides ----
  cal_pest <- extract_tables("data/raw/pesticide_sedac/CalEnviroScreen40_PESTICIDE_LIST.pdf")
  cal_pest_all <- list()
  
  # Clean and stitch together pages of table
  for (i in 1:length(cal_pest)) {
    df_df <- data.frame(cal_pest[i])
    df_cut <- df_df[-(1:3),]
    
    cal_pest_all[[i]] <- df_cut
  }
  
  cal_pest <- cal_pest_all %>% 
    bind_rows(.)
  
  # Clean extra blank spaces, rename variables
  cal_pest_clean <- cal_pest %>% 
    filter(if_all(.cols = everything(), ~ .x != "")) %>% 
    rename_all(., ~c("pesticide_active_ingredient", "use_2017_19_lbs", "enviroscreen_rank"))
  
  # Final list of pesticides from CalEnviroScreen
  cal_pest_list <- tolower(unique(cal_pest_clean$pesticide_active_ingredient))
  
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
    
    # Replace negative values with NA
    rast_H[rast_H < 0] <- NA
    rast_L[rast_L < 0] <- NA
    
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
  
  # Get unique facility IDs, apply 1km buffer
  prisons <- read_sf('data/processed/study_prisons.shp') %>% 
    st_transform(crs = 4326) %>% 
    st_buffer(1000)
  
  pesticide_sum_84 <- project(pesticide_sum, prisons)
  
  names(pesticide_sum_84) <- "pesticide_sum_kg_ha.year"
  
  # Extract usage (kg/ha-year) using terra::extract()
  prisons_pest <- prisons %>% 
    mutate(pesticide_use = terra::extract(pesticide_sum_84, prisons, fun = "mean", na.rm = TRUE)) %>% 
    unnest(cols = pesticide_use) %>% 
    select(!ID)
  
  return(prisons_pest)
}

## TEST ----
test_calcPesticides <- calcPesticides("data/raw/pesticide_sedac/ferman-v1-pest-chemgrids-v1-01-geotiff")

### Visualize Results ----
prisons <- prisons_pest %>% 
  st_centroid(.)

pal1 <- colorNumeric(palette = "Reds", domain = prisons$pesticide_sum_kg_ha.year)

leaflet(prisons) %>% 
  addTiles() %>% 
  addCircleMarkers(color = ~pal1(pesticide_sum_kg_ha.year),
              radius = 5,
              stroke = FALSE, fillOpacity = 1) %>% 
  addLegend(pal = pal1,
            values = ~pesticide_sum_kg_ha.year,
            title = "Pesticide Usage (kg/ha*year)")


