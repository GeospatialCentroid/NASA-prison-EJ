#' Calculate NPL (national priority list)/Superfund facility proximity
#' 
#' This function calculates NPL facility proximity as the count of proposed and listed NPL
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param file The filepath to the NPL csv file
#' @param dist The distance (in meters) to count facilities within. Default is 5000 (5km)
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with summed proximity values for each prison
getNPL <- function(prisons, file = "data/processed/npl_addresses_geocoded_arc_sf.csv", 
                   dist = 5000, save = FALSE, path = NULL){
  
  npl <- read_csv(file) %>% 
    #keep only listed and proposed NPL
    filter(str_detect(npl_status, "Final|Proposed")) %>% 
    separate(geometry, into = c("Long", "Lat"), sep = ",") %>% 
    mutate(Long = str_remove(Long, ".*\\("),
           Lat = str_remove(Lat, "\\)")) %>%
    filter(!is.na(Long) | !is.na(Lat)) %>% 
    st_as_sf(coords = c("Long", "Lat"), crs = 4326) %>% 
    st_transform(crs = st_crs(prisons))
  
  
  npl_prox <- effectsProximity(prisons, npl, dist = dist) %>% 
    rename(npl_prox = proximity_score)
  
  
  if(save == TRUE) {
    
    write_csv(npl_prox, file = paste0(path, "/npl_prox_", Sys.Date(), ".csv"))
    
  }
  
  
  
}