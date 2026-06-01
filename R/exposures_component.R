#' Calculate Environmental Exposures component scores
#'
#' This function runs all the functions to process environmental exposure indicators
#'
#' @param sf_obj          An sf object of all facility polygons to be assessed
#' @param ozone_folder    The filepath to the folder with all the Ozone .txt.gz files
#' @param pm25_folder     The filepath to the folder with all the PM2.5 rasters
#' @param pesticide_folder The filepath to the folder with all the pesticide .nc files
#' @param traffic_file    The filepath to the .RData file for the 2023 U.S. AADT shapefile.
#'                        See 'process_traffic.R' script for how this was processed
#' @param pm25_dist       Buffer distance (m) for calc_pm25(). Default 1000m.
#' @param pesticide_dist  Buffer distance (m) for calc_pesticides(). Default 0m
#'                        (kept at 0 since the pesticide raster is ~5km resolution).
#' @param traffic_dist    Buffer distance (m) for calc_traffic_proximity(). Default 500m.
#' @param id_column       A string specifying the name of the unique facility identifier column
#'                        (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                        Default is "FACILITYID".
#' @param save            Whether to save the resulting dataframe (as .csv) or not
#' @param out_path        If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each indicator and the exposure component score
exposures_component <-
  function(sf_obj,
           ozone_folder,
           pm25_folder,
           pesticide_folder,
           traffic_file,
           pm25_dist = 1000,
           pesticide_dist = 0,
           traffic_dist = 500,
           id_column = "FACILITYID",
           save = TRUE,
           out_path = "outputs/") {
    
    # ozone
    ozone <- calc_ozone(
      sf_obj    = sf_obj,
      folder    = ozone_folder,
      id_column = id_column,
      out_path  = out_path
    )
    print("Ozone indicator calculated")
    
    # pm2.5
    pm25 <- calc_pm25(
      sf_obj    = sf_obj,
      folder    = pm25_folder,
      dist      = pm25_dist,
      id_column = id_column,
      years = c(2021, 2023),
      out_path  = out_path
    )
    print("PM2.5 indicator calculated")
    
    # pesticides
    pesticides <- calc_pesticides(
      sf_obj    = sf_obj,
      folder    = pesticide_folder,
      dist      = pesticide_dist,
      id_column = id_column,
      save      = TRUE,
      out_path  = out_path
    )
    print("Pesticides indicator calculated")
    
    # traffic proximity (takes 1.5 days to run on Desktop comp)
    traffic_prox <- calc_traffic_proximity(
      sf_obj    = sf_obj,
      file      = traffic_file,
      dist      = traffic_dist,
      id_column = id_column,
      out_path  = out_path
    )
    print("Traffic proximity indicator calculated")
    
    # join data frames and calculate exposures component score
    df <- list(ozone, pm25, pesticides, traffic_prox) %>%
      purrr::map(~ .x %>% mutate(!!sym(id_column) := as.character(!!sym(id_column)))) %>%
      purrr::reduce(left_join, by = id_column) %>%
      # calculate percentile columns for each raw indicator
      dplyr::mutate(across(
        where(is.numeric),
        .fns = list(pcntl = ~ cume_dist(.) * 100),
        .names = "{col}_{fn}"
      )) %>%
      rowwise() %>%
      # calculate exposure component score (geometric mean of indicator percentiles)
      mutate(exposure_score = gm_mean(c_across(contains("pcntl"))))
    
    if (save == TRUE) {
      write_csv(df, file = paste0(out_path, "/exposures_component_", Sys.Date(), ".csv"))
      print(paste("Exposures component saved to", out_path))
    }
    
    return(df)
  }