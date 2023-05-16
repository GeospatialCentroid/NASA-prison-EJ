#' Calculate climate component scores
#' 
#' This function runs all the functions to process climate component indicators, and in this case also reads in the
#' output data from the GEE scripts in the python/ folder
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param heat_risk A file path to the .csv output of heat risk for each prison from the python/modis_lst.py script
#' @param canopy_cover A file path to the .csv output of canopy cover for each prison from the python/NLCD_canpoy_cover.py script
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' @param date A date tag to add to the file name to track versions. Default is current date
#' 
#' @return A tibble with raw values and percentiles for each climate indicator and the climate component score
climateComponent <- function(prisons, heat_risk, canpoy_cover, save = FALSE, path = "data/processed/", date = Sys.Date()){
  
  
  #run climate indicator functions
  floodRisk <- getFloodRisk(prisons, dist = 1000)
  
  wildfireRisk <- getWildfireRisk(prisons, dist = 1000)
  
  
  #read in outputs from modis and canopy cover GEE scripts
  
  heatRisk <- read_csv(heat_risk)
  
  canopyCover <- read_csv(canopy_cover)
  
  
  
  # join data frames and calculate climate component score
  
  df <- list(floodRisk, wildfireRisk, heatRisk, canopyCover) %>%
    purrr::reduce(left_join, by = "FACILITYID") %>%
    #calculate percentile columns for each raw indicator
    dplyr::mutate(across(
      where(is.numeric),
      .fns = list(pcntl = ~ cume_dist(.) * 100),
      .names = "{col}_{fn}"
    )) %>%
    # calculate climate component score (average all indicator percentile values per prison
    mutate(climateScore = rowMeans(select(., contains("pcntl"))))
  
  if (save == TRUE) {
    
    write_csv(df, file = paste0(path,"/climateComponent_", date, ".csv"))
    
  }
  
  return(df)
  
  
}
