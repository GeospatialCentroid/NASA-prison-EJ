#' Calculate Environmental Effects component scores
#'
#' This function runs all the functions to process environmental exposure indicators
#'
#' @param prisons An sf object of all prison polygons to be assessed
#' @param save Whether to save the resulting dataframe (as .csv) or not
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each indicator and the exposure component score
exposures_component <- function(prisons, save = TRUE, path = "outputs/") {
  
  # calculate Risk Management Plan (RMP) facility proximity
  rmp_prox <- calc_rmp_proximity(
    sf_obj = prisons,
    file = "data/raw/EPA_RMP/EPA_Emergency_Response_(ER)_Risk_Management_Plan_(RMP)_Facilities.csv"
  )
  # calculate NPL facility proximity
  npl_prox <- calc_npl_proximity(
    sf_obj = prisons,
    file = "data/processed/npl_addresses_geocoded_arc_sf.csv"
  )
  
  
  # calculate Haz waste facility proximity
  haz_prox <- calc_haz_waste_proximity(
    sf_obj = prisons,
    file = "data/processed/hazardous_waste/TSD_LQGs.csv"
  )
  
  
  
  # join data frames and calculate climate component score
  
  df <- list(rmp_prox, npl_prox, haz_prox) %>%
    purrr::reduce(left_join, by = "FACILITYID") %>%
    # make facility ID character
    mutate(FACILITYID = as.character(FACILITYID)) %>%
    # calculate percentile columns for each raw indicator
    dplyr::mutate(across(
      where(is.numeric),
      .fns = list(pcntl = ~ cume_dist(.) * 100),
      .names = "{col}_{fn}"
    )) %>%
    rowwise() %>%
    # calculate climate component score (geometric mean of indicator percentiles)
    mutate(effects_score = gm_mean(c_across(contains("pcntl"))))
  
  
  if (save == TRUE) {
    write_csv(df, file = paste0(out_path, "/effects_component_", Sys.Date(), ".csv"))
  }
  
  return(df)
  
}