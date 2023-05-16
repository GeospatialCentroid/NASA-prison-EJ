#' Calculate hazardous waste facility proximity
#' 
#' This function calculates hazardous waste facility proximity as the count of haz waste
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param file The filepath to the hazardous waste csv file
#' @param dist The distance ( in meters) to count facilities within. Default is 5000 (5km)
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getHazWaste <- function(prisons, file = "data/raw/hazardous_waste/TSD_LQGs_raw.csv", 
                   dist = 5000, save = FALSE, path = NULL){
  
  haz <- read_csv(file) %>% 
    #NOTE, may need to geocode the couple thousand NA coords
    filter(!is.na(LONGITUDE83) | !is.na(LATITUDE83)) %>% 
    st_as_sf(coords = c("LONGITUDE83", "LATITUDE83"), crs = 4269) %>% 
    st_transform(crs = st_crs(prisons))
  
  
  haz_prox <- effectsProximity(prisons, haz, dist = dist) %>% 
    rename(haz_prox = proximity_score)
  
  
  if(save == TRUE) {
    
    write_csv(haz_prox, file = paste0(path, "/haz_prox_", Sys.Date(), ".csv"))
    
  }
  
  
  
}