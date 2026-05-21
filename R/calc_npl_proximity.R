#' Calculate NPL (national priority list)/Superfund facility proximity
#'
#' This function calculates NPL facility proximity as the count of proposed and listed NPL
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#'
#' @param sf_obj    An sf object of all polygons to be assessed
#' @param file      The filepath to the NPL geocoded shape file (or csv file type for older implementation)
#' @param dist      The distance (in meters) to count facilities within. Default is 5000 (5km)
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#' @param save      Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path  If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with summed proximity scores for each buffered polygon
calc_npl_proximity <- function(sf_obj,
                               file,
                               dist = 5000,
                               id_column = "FACILITYID",
                               save = TRUE,
                               out_path = "outputs/") {
  
  # check file type
  extension <- file_ext(file)
  
  if (extension == "csv") {
    
    npl <- read_csv(file) %>%
      # keep only listed and proposed NPL
      filter(str_detect(npl_status, "Final|Proposed")) %>%
      separate(geometry, into = c("Long", "Lat"), sep = ",") %>%
      mutate(
        Long = str_remove(Long, ".*\\("),
        Lat  = str_remove(Lat, "\\)")
      ) %>%
      filter(!is.na(Long) | !is.na(Lat)) %>%
      st_as_sf(coords = c("Long", "Lat"), crs = 4326) %>%
      st_transform(crs = st_crs(sf_obj))
    
  } else if (extension == "shp") {
    
    npl <- read_sf(file) %>%
      filter(str_detect(NPL_Status, "Final|Proposed")) %>%
      st_transform(crs = st_crs(sf_obj)) %>% 
      # remove any empty geometries
      filter(!st_is_empty(st_geometry(.)))
    
  }
  
  npl_prox <- effects_proximity(sf_obj, npl, dist = dist, id_column = id_column) %>%
    rename(npl_prox = proximity_score)
  
  if (save == TRUE) {
    write_csv(npl_prox, file = paste0(out_path, "/npl_proximity_", Sys.Date(), ".csv"))
  }
  
  return(npl_prox)
}