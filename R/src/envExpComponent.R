#' Calculate Environmental Exposures component scores
#' 
#' This function runs all the functions to process environmental exposure indicators
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param save Whether to save the resulting dataframe (as .csv) or not
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with raw values and percentiles for each climate indicator and the climate component score
envExpComponent <- function(prisons, heat_risk, canpoy_cover, save = FALSE, path = "data/processed/"){
  
  
  #run indicator functions
  ozone <- getOzone(prisons, folder = , dist = 1000)
  
  pm25 <- getPM25(prisons, folder = , dist = 1000)
  
  pesticides <- calcPesticides(prisons)
  
  traffic_prox <- getTrafficProximity(prisons, file = "data/processed/traffic_proximity/aadt_2018.RData",
                                      save = TRUE, path = "data/processed/")
  
  
  
  # join data frames and calculate climate component score
  
  df <- list(ozone, pm25, pesticides, traffic_prox) %>%
    purrr::reduce(left_join, by = "FACILITYID") %>%
    # calculate percentile columns for each raw indicator
    dplyr::mutate(across(
      where(is.numeric),
      .fns = list(pcntl = ~ cume_dist(.) * 100),
      .names = "{col}_{fn}"
    )) %>%
    # calculate climate component score (average all indicator percentile values per prison
    mutate(climateScore = rowMeans(select(., contains("pcntl"))))
  
  if (save == TRUE) {
    
    write_csv(df, file = paste0(path,"/envExpComponent_", Sys.Date(), ".csv"))
    
  }
  
  return(df)
  
  
}
