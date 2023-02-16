#' Calculate PM2.5 risk
#' 
#' This function calculates the PM2.5 levels averaged within each prison boundary + buffer using the
#' SEDAC 1km CONUS PM2.5 dataset for 2000-2016
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param folder The filepath to the folder with all the PM2.5 rasters
#' @param dist The buffer distance (in meters) to add around prison boundaries
#' @param years The year range (given as a vector) to average Ozone over. Must be within 2000-2016
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getOzone <- function(prisons, folder, dist = 5000, years = c(2000, 2016), save = FALSE, path = 'data/processed'){
  
  #import and calculate avg annual ozone for specified year range
  
  files <- list.files(folder, pattern = ".tif", full.names = TRUE)
  
  avg_pm25 <- paste0(as.character(years[1]:years[2]), ".tif") %>%
    map_chr( ~ str_subset(files, .x)) %>% 
    terra::rast() %>% 
    mean()
  
  
  # buffer prisons by dist
  prisons_buff <- prisons %>% 
    st_buffer(dist = dist)
  
  # check if CRS match, if not transform prisons
  if (crs(prisons) != crs(avg_pm25)) {
    
    prisons_buff <- st_transform(prisons_buff, crs = crs(avg_pm25))
  }
  
  
  # calculate average ozone within each buffer
  prisons_buff$avg_pm25 <- terra::extract(avg_pm25, prisons_buff, fun = "mean", na.rm = TRUE)[,2]
  
  # clean dataset to return just prison ID and calculated value
  prison_pm25 <- prisons_buff %>% 
    st_drop_geometry() %>% 
    select(FACILITYID, avg_pm25)
  
  
  
  if(save == TRUE) {
    
    write_csv(prison_pm25, file = paste0(path, "/pm25_", Sys.Date(), ".csv"))
    
  }
  
  
  return(prison_pm25)  
  
  
  
}
