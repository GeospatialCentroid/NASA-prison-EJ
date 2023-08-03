#' Calculate proximity scores for environmental effects indicators
#'
#' This function calculates a proximity score that is the count of all features within a specified
#' distance (or the nearest feature if none within specified distance) each divided by its distance
#' to target features and summed across each target feature
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param points An sf object of points to calculate proximity to
#' @param dist The distance (in meters) to find features within

#' @return A tibble of proximity score for each polygon
effects_proximity <- function(sf_obj, points, dist) {
  # find all points w/in buffer
  prison_dist <- sf_obj %>%
    mutate(find_points = st_is_within_distance(., points, dist = dist)) %>%
    unnest(find_points)


  # IF none, find nearest
  prison_nearest <- sf_obj %>%
    # filter prisons dropped in dist calc (meaning no points within dist)
    filter(!FACILITYID %in% prison_dist$FACILITYID) %>%
    mutate(find_points = st_nearest_feature(., points))

  # unnest list column
  prison_scores <- bind_rows(prison_dist, prison_nearest) %>%
    unnest(find_points)

  # calc distance
  prison_scores$distance <- st_distance(prison_scores, points[prison_scores$find_points, ], by_element = TRUE)


  # group by prisons and calc final scores
  prison_scores <- prison_scores %>%
    mutate(distance = as.numeric(distance) / 1000) %>%
    group_by(FACILITYID) %>%
    summarize(proximity_score = sum(1 / distance)) %>%
    st_drop_geometry()

  return(prison_scores)
}
