#' Calculate NPL (national priority list)/Superfund facility proximity
#' 
#' This function calculates NPL facility proximity as the count of proposed and listed NPL
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#' 
#' @param sf_obj An sf object of all polygons to be assessed
#' @param file The filepath to the NPL csv file
#' @param dist The distance (in meters) to count facilities within. Default is 5000 (5km)
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with summed proximity scores for each buffered polygon
calc_npl_proximity <- function(sf_obj,
                     file,
                     dist = 5000,
                     save = TRUE,
                     out_path = "outputs/") {
  
  npl <- read_csv(file) %>% 
    #keep only listed and proposed NPL
    filter(str_detect(npl_status, "Final|Proposed")) %>% 
    separate(geometry, into = c("Long", "Lat"), sep = ",") %>% 
    mutate(Long = str_remove(Long, ".*\\("),
           Lat = str_remove(Lat, "\\)")) %>%
    filter(!is.na(Long) | !is.na(Lat)) %>% 
    st_as_sf(coords = c("Long", "Lat"), crs = 4326) %>% 
    st_transform(crs = st_crs(sf_obj))
  
  
  npl_prox <- effects_proximity(sf_obj, npl, dist = dist) %>% 
    rename(npl_prox = proximity_score)
  
  
  if(save == TRUE) {
    
    write_csv(npl_prox, file = paste0(out_path, "/npl_proximity_", Sys.Date(), ".csv"))
    
  }
  
  
  
}