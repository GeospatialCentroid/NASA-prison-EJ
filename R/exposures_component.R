#' Calculate Environmental Exposures component scores
#'
#' This function runs all the functions to process environmental exposure indicators
#'
#' @param prisons An sf object of all prison polygons to be assessed
#' @param ozone_folder The filepath to the folder with all the Ozone rasters (one for each month/year)
#' @param pm25_folder The filepath to the folder with all the PM2.5 rasters
#' @param pesticide_folder The filepath to the folder with all the pesticide rasters
#' @param traffic_file The filepath to the .RData file for the 2018 U.S. AADT shapefile. See 'process_traffic.R' script for how this was processed
#' @param save Whether to save the resulting dataframe (as .csv) or not
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each indicator and the exposure component score
exposures_component <-
  function(prisons,
           ozone_folder,
           pm25_folder,
           pesticide_folder,
           traffic_file,
           save = TRUE,
           out_path = "outputs/") {
    # run indicator functions
  # ozone
  ozone <- calc_ozone(
    sf_obj = prisons, folder = ozone_folder,
    dist = 1000, years = c(2015, 2016),
    out_path = out_path
  )

  print("Ozone indicator calculated")

  # pm2.5 (may change dataset, check for more recent years)
  pm25 <-
    calc_pm25(
      sf_obj = prisons,
      folder = pm25_folder,
      dist = 1000,
      years = c(2015, 2016),
      out_path = out_path
    )

  print("PM 2.5 indicator calculated")

  # pesticides (ran this manually to save time re-creating all rasters)
  pesticides <- calc_pesticides(prisons, 
                                folder = pesticide_folder,
                                dist = 1000, 
                                save = TRUE,
                                out_path = out_path)

  print("Pesticides indicator calculated")

  # traffic proximity (takes 1.5 days to run on Desktop comp)
  traffic_prox <- calc_traffic_proximity(
    sf_obj = prisons,
    file = traffic_file,
    out_path = out_path
  )
  
  print("Traffic proximity indicator calculated")




  # join data frames and calculate climate component score

  df <- list(ozone, pm25, pesticides, traffic_prox) %>%
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
    mutate(exposure_score = gm_mean(c_across(contains("pcntl"))))


  if (save == TRUE) {
    write_csv(df, file = paste0(out_path, "/exposures_component_", Sys.Date(), ".csv"))
    
    print(paste("Exposures component saved to", out_path))
    
    }

  return(df)
}
