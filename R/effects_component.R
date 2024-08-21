#' Calculate Environmental Effects component scores
#'
#' This function runs all the functions to process environmental exposure indicators
#'
#' @param prisons An sf object of all prison polygons to be assessed
#' @param rmp_file The filepath to the RMP csv file
#' @param npl_file The filepath to the NPL csv file
#' @param haz_file The filepath to the hazardous waste csv file
#' @param save Whether to save the resulting dataframe (as .csv) or not
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each indicator and the exposure component score
effects_component <-
  function(prisons,
           rmp_file,
           npl_file,
           haz_file,
           save = TRUE,
           out_path = "outputs/"
  ) {
  
  # calculate Risk Management Plan (RMP) facility proximity
  rmp_prox <- calc_rmp_proximity(
    sf_obj = prisons,
    file = rmp_file,
    out_path = out_path
  )
  
  print("RMP proximity caculated")
  
  
  # calculate NPL facility proximity
  npl_prox <- calc_npl_proximity(
    sf_obj = prisons,
    file = npl_file,
    out_path = out_path
  )
  
  print("NPL proximity calculated")
  
  # calculate Haz waste facility proximity
  haz_prox <- calc_haz_waste_proximity(
    sf_obj = prisons,
    file = haz_file,
    out_path = out_path
  )
  
  print("Hazardous waste facility proximity calculated")
  
  
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
    write_csv(df,
              file = paste0(out_path, "/effects_component_", Sys.Date(), ".csv"))
    
    print(paste("Effects component data saved to", out_path))
  }
  
  return(df)
  
}