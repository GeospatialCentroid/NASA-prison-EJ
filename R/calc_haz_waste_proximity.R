#' Calculate hazardous waste facility proximity
#'
#' This function calculates hazardous waste facility proximity as the count of haz waste
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param file The filepath to the hazardous waste csv file
#' @param dist The distance ( in meters) to count facilities within. Default is 5000 (5km)
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with summed proximity scores for each buffered polygon
calc_haz_waste_proximity <- function(sf_obj,
                                     file,
                                     dist = 5000,
                                     save = TRUE,
                                     out_path = "outputs/") {
  haz <- read_csv(file) %>%
    # NOTE, may need to geocode the couple thousand NA coords
    filter(!is.na(LONGITUDE83) | !is.na(LATITUDE83)) %>%
    st_as_sf(coords = c("LONGITUDE83", "LATITUDE83"), crs = 4269) %>%
    st_transform(crs = st_crs(sf_obj))


  haz_prox <- effects_proximity(sf_obj, haz, dist = dist) %>%
    rename(haz_prox = proximity_score)


  if (save == TRUE) {
    write_csv(haz_prox, file = paste0(out_path, "/hazardous_waste_proximity_", Sys.Date(), ".csv"))
  }
}
