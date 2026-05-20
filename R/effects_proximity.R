#' Calculate proximity scores for environmental effects indicators
#'
#' This function calculates a proximity score that is the count of all features within a specified
#' distance (or the nearest feature if none within specified distance) each divided by its distance
#' to target features and summed across each target feature
#'
#' @param sf_obj    An sf object of all polygons to be assessed
#' @param points    An sf object of points to calculate proximity to
#' @param dist      The distance (in meters) to find features within
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#'
#' @return A tibble of proximity score for each polygon
effects_proximity <- function(sf_obj, points, dist, id_column = "FACILITYID") {
  
  # find all points w/in buffer — unnest immediately to integer rows
  facility_dist <- sf_obj %>%
    mutate(find_points = st_is_within_distance(., points, dist = dist)) %>%
    unnest(find_points)                          # list -> one row per match
  
  # facilities with no matches within dist -> fall back to nearest
  facility_nearest <- sf_obj %>%
    filter(!.data[[id_column]] %in% facility_dist[[id_column]]) %>%
    mutate(find_points = st_nearest_feature(., points))  # already integer
  
  # bind — both have plain integer find_points now, no type mismatch
  facility_scores <- bind_rows(facility_dist, facility_nearest) %>%
    filter(!is.na(find_points))                  # drop any coercion casualties
  
  # calc distance
  facility_scores$distance <- st_distance(
    facility_scores, points[facility_scores$find_points, ], by_element = TRUE
  )
  
  facility_scores <- facility_scores %>%
    filter(!is.na(distance)) %>%                 # drop any remaining NA distances
    mutate(
      distance = as.numeric(distance) / 1000,
      distance = if_else(distance == 0, 0.001, distance)
    ) %>%
    group_by(!!sym(id_column)) %>%
    summarize(proximity_score = sum(1 / distance)) %>%
    st_drop_geometry()
  
  return(facility_scores)
}