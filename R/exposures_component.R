#' Calculate Environmental Exposures component scores
#'
#' This function runs all the functions to process environmental exposure indicators
#'
#' @param prisons An sf object of all prison polygons to be assessed
#' @param save Whether to save the resulting dataframe (as .csv) or not
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each indicator and the exposure component score
exposures_component <- function(prisons, save = TRUE, path = "outputs") {
  # run indicator functions
  # ozone
  ozone <- calc_ozone(
    sf_obj = prisons, folder = "data/raw/air_quality/o3-us-1-km-2000-2016-annual/",
    dist = 1000, years = c(2015, 2016)
  )

  print("Ozone indicator calculated")

  # pm2.5 (may change dataset, check for more recent years)
  pm25 <-
    calc_pm25(
      sf_obj = prisons,
      folder = "data/raw/air_quality/pm2-5-us-1-km-2000-2016-annual/",
      dist = 1000,
      years = c(2015, 2016)
    )

  print("PM 2.5 indicator calculated")

  # pesticides (ran this manually to save time re-creating all rasters)
  pesticides <- calcPesticides(prisons, dist = 1000, save = TRUE)

  print("Pesticides indicator calculated")

  # traffic proximity (takes 1.5 days to run on Desktop comp)
  traffic_prox <- calc_traffic_proximity(
    sf_obj = prisons,
    file = "data/processed/traffic_proximity/aadt_2018.RData"
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
