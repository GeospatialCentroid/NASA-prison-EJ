#' Calculate Risk Management Plan (RMP) facility proximity
#'
#' This function calculates RMP facility proximity as the count of RMP (potential chemical accident management plan)
#' facilities within 5km (or nearest one beyond 5km) each divided by the distance in km.
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param file The filepath to the RMP csv file
#' @param dist The distance ( in meters) to count facilities within. Default is 5000 (5km)
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with summed proximity scores for each buffered polygon
calc_rmp_proximity <- function(sf_obj,
                     file,
                     dist = 5000,
                     save = TRUE,
                     out_path = "outputs/") {
  rmp <- read_csv(file) %>%
    st_as_sf(coords = c("LONGITUDE8", "LATITUDE83"), crs = 4269) %>%
    st_transform(crs = st_crs(sf_obj))


  rmp_prox <- effects_proximity(sf_obj, rmp, dist = dist) %>%
    rename(rmp_prox = proximity_score)


  if (save == TRUE) {
    write_csv(rmp_prox, file = paste0(out_path, "/rmp_proximity_", Sys.Date(), ".csv"))
  }
}
