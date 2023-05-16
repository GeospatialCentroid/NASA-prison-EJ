#' Calculate Risk Management Plan (RMP) facility proximity
#' 
#' This function calculates RMP facility proximity as the count of RMP (potential chemical accident management plan)
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param file The filepath to the RMP csv file
#' @param dist The distance ( in meters) to count facilities within. Default is 5000 (5km)
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getRMP <- function(prisons, file = "data/raw/EPA_RMP/EPA_Emergency_Response_(ER)_Risk_Management_Plan_(RMP)_Facilities.csv", 
                                dist = 5000, save = FALSE, path = NULL){
  
  rmp <- read_csv(file) %>% 
    st_as_sf(coords = c("LONGITUDE8", "LATITUDE83"), crs = 4269) %>% 
    st_transform(crs = st_crs(prisons))
  
  
  rmp_prox <- effectsProximity(prisons, rmp, dist = dist) %>% 
    rename(rmp_prox = proximity_score)
  
  
  if(save == TRUE) {
    
    write_csv(rmp_prox, file = paste0(path, "/rmp_prox_", Sys.Date(), ".csv"))
    
  }
  
  
  
}