#' Calculate PM2.5 risk
#' 
#' This function calculates the PM2.5 levels averaged within each prison boundary + buffer using the
#' SEDAC 1km CONUS PM2.5 dataset for 2000-2016
#' 
#' @param sf_obj An sf object of all polygons to be assessed
#' @param folder The filepath to the folder with all the PM2.5 rasters
#' @param dist The buffer distance (in meters) to add around polygon boundaries
#' @param years The year range (given as a vector) to average PM 2.5 over. Must be within 2000-2016
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with total mean PM 2.5 across selected years within each buffered polygon boundary
calc_pm25 <-
  function(sf_obj,
           folder,
           dist = 1000,
           years = c(2017, 2019),
           save = TRUE,
           out_path = 'outputs/') {
    
  #import and calculate avg annual ozone for specified year range
  
  files <- list.files(folder, pattern = ".tif$", full.names = TRUE)
  
  avg_pm25 <- paste0(as.character(years[1]:years[2]), ".tif") %>%
    map_chr( ~ str_subset(files, .x)) %>% 
    terra::rast() %>% 
    mean()
  
  
  # buffer prisons by dist
  sf_buff <- sf_obj %>% 
    st_buffer(dist = dist)
  
  # check if CRS match, if not transform prisons
  if (crs(sf_obj) != crs(avg_pm25)) {
    
    sf_buff <- st_transform(sf_buff, crs = crs(avg_pm25))
  }
  
  
  # calculate average ozone within each buffer
  sf_buff$avg_pm25 <- terra::extract(avg_pm25, sf_buff, fun = "mean", na.rm = TRUE)[,2]
  
  # clean dataset to return just prison ID and calculated value
  sf_pm25 <- sf_buff %>% 
    st_drop_geometry() %>% 
    select(FACILITYID, avg_pm25)
  
  
  
  if(save == TRUE) {
    
    write_csv(sf_pm25, file = paste0(out_path, "/pm25_", Sys.Date(), ".csv"))
    
  }
  
  
  return(sf_pm25)  
  
  
  
}
