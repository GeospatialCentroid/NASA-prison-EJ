#' Calculate Environmental Effects component scores
#'
#' This function runs all the functions to process environmental effects indicators
#'
#' @param sf_obj    An sf object of all facility polygons to be assessed
#' @param rmp_file  The filepath to the RMP csv file
#' @param npl_file  The filepath to the NPL csv file
#' @param haz_file  The filepath to the hazardous waste csv file
#' @param rmp_dist  Buffer distance (m) for calc_rmp_proximity(). Default 5000m.
#' @param npl_dist  Buffer distance (m) for calc_npl_proximity(). Default 5000m.
#' @param haz_dist  Buffer distance (m) for calc_haz_waste_proximity(). Default 5000m.
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#' @param save      Whether to save the resulting dataframe (as .csv) or not
#' @param out_path  If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each indicator and the effects component score
effects_component <-
  function(sf_obj,
           rmp_file,
           npl_file,
           haz_file,
           rmp_dist  = 5000,
           npl_dist  = 5000,
           haz_dist  = 5000,
           id_column = "FACILITYID",
           save      = TRUE,
           out_path  = "outputs/") {
    
    # calculate Risk Management Plan (RMP) facility proximity
    rmp_prox <- calc_rmp_proximity(
      sf_obj    = sf_obj,
      file      = rmp_file,
      dist      = rmp_dist,
      id_column = id_column,
      out_path  = out_path
    )
    print("RMP proximity calculated")
    
    # calculate NPL facility proximity
    npl_prox <- calc_npl_proximity(
      sf_obj    = sf_obj,
      file      = npl_file,
      dist      = npl_dist,
      id_column = id_column,
      out_path  = out_path
    )
    print("NPL proximity calculated")
    
    # calculate haz waste facility proximity
    haz_prox <- calc_haz_waste_proximity(
      sf_obj    = sf_obj,
      file      = haz_file,
      dist      = haz_dist,
      id_column = id_column,
      out_path  = out_path
    )
    print("Hazardous waste facility proximity calculated")
    
    # join data frames and calculate effects component score
    df <- list(rmp_prox, npl_prox, haz_prox) %>%
      purrr::map(~ .x %>% mutate(!!sym(id_column) := as.character(!!sym(id_column)))) %>%
      purrr::reduce(left_join, by = id_column) %>%
      # calculate percentile columns for each raw indicator
      dplyr::mutate(across(
        where(is.numeric),
        .fns = list(pcntl = ~ cume_dist(.) * 100),
        .names = "{col}_{fn}"
      )) %>%
      rowwise() %>%
      # calculate effects component score (geometric mean of indicator percentiles)
      mutate(effects_score = gm_mean(c_across(contains("pcntl"))))
    
    if (save == TRUE) {
      write_csv(df, file = paste0(out_path, "/effects_component_", Sys.Date(), ".csv"))
      print(paste("Effects component data saved to", out_path))
    }
    
    return(df)
  }