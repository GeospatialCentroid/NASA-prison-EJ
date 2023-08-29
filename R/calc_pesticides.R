#' Calculate pesticide application quantities
#' 
#' This function uses Application Rate from SEDAC PEST-CHEMGRIDS rasters and calculates
#' the quantity of all pesticides used within boundary + specified buffer.
#' 
#' @param sf_obj An sf object of all polygons to be assessed
#' @param folder The filepath to the folder with all the pesticide rasters
#' @param dist The buffer distance (in meters) to add around prison boundaries
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to the folder to save the output csv to
#' 
#' @return The total average pesticide application from 2020 in kg/ha*yr

calc_pesticides <-
  function(sf_obj,
           folder = "data/raw/pesticides/ferman-v1-pest-chemgrids-v1-01-geotiff",
           dist = 1000,
           save = TRUE,
           out_path = 'outputs/') {
    
    
    
    # Read in SEDAC ApplicationRate .tif(s)
    sedac_filenames <- list.files(path = paste0(folder,"/ApplicationRate/GEOTIFF"), 
                                  pattern = ".tif$",
                                  full.names = TRUE) %>% 
      purrr::keep(grepl('2015', .))
    
    
    ### GENERATE pesticide AVG files, create SUM spatRaster ----
    rast_mean <- list()
    
    # Iterating over each pair of pesticide / crop to calculate mean values from H/L
    for (i in seq(1, (length(sedac_filenames)), 2)) {
      
      # Load the two corresponding High and Low estimate rasters
      rast_H <- terra::rast(sedac_filenames[i])
      rast_L <- terra::rast(sedac_filenames[i + 1])
      
      # Replace negative values with zero
      rast_H[rast_H < 0] <- 0
      rast_L[rast_L < 0] <- 0
      
      # calculate average from H/L
      rast_mean[[i]] <- mean(rast_H, rast_L)
      
      print(i)
      
    }
    
    # stack rasters and sum application rates for each pixel
    rast_total <- rast(rast_mean)
    
    total_sum <- sum(rast_total)
    
    # save this raster while testing
    # writeRaster(total_sum, "data/processed/pesticides/pesticide_sum_2015.tif")
    
    

    ## Calculate total application rate averaged within each prison polygon ----
    
    
    # check if CRS match, if not transform prisons
    if (crs(sf_obj) != crs(total_sum)) {
      sf_obj <- st_transform(sf_obj, crs = crs(total_sum))
    }
    
    # Extract usage (kg/ha)
    prisons_pest <- sf_obj %>% 
      st_buffer(dist = dist) %>% 
      mutate(pesticide_use = terra::extract(total_sum, ., fun = "mean", na.rm = TRUE)) %>% 
      unnest(cols = pesticide_use) %>% 
      select(FACILITYID, pesticides = sum) %>% 
      st_drop_geometry()
    
    if (save == TRUE) {
      
      write_csv(prisons_pest, paste0(out_path, "/pesticides_", Sys.Date(), ".csv"))
      
    }
    
  }