#' Calculate wildfire risk
#' 
#' This function calls flood zone data from the FEMA ArcGIS map services and calculates the
#' percent of each prison boundary + buffer is covered by high risk flood zones (zones A | Z)
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param filePath the file path pointing to the folder with the 3 wildfire raster layers
#' @param dist The buffer distance (in meters) to add around prison boundaries
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param path If `save = TRUE`, the file path to the folder to save the output csv to.
#' @param date A date tag to add to the file name to track versions. Default is current date
#' 
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getWildfireRisk <- function(prisons, filePath = "L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/", 
                            dist = 1000, save = TRUE, path = 'data/processed/', date = Sys.Date()){
  
  #buffer prison
  prison_buffer <- st_buffer(prisons, dist) %>% 
    st_make_valid()
  
  
  #read in rasters from file
  ### Wildfire Risk Raster (L:Drive) ----
  
  wf_conus <- rast(paste0(filePath, "whp2020_cnt_conus.tif"))
  wf_ak <- rast(paste0(filePath, "whp2020_cnt_ak.tif"))
  wf_hi <- rast(paste0(filePath, "whp2020_cnt_hi.tif"))
  
  
  #need to separate prisons file for conus, ak and hi and project to matching raster
  prisons_conus <- prison_buffer %>% filter(!(STATE %in% c("AK", "HI"))) %>% 
    st_transform(st_crs(wf_conus))
  
  prisons_ak <- prison_buffer %>% filter(STATE == "AK") %>% 
    st_transform(st_crs(wf_ak))
  
  prisons_hi <- prison_buffer %>% filter(STATE == "HI") %>% 
    st_transform(st_crs(wf_hi))
  

  
  # create function to calculate average wf risk within each prison boundary
  
  wfRiskCalc <- function(prison_obj, raster_obj){
    
    df <- prison_obj %>% 
      mutate(wildfire_risk = terra::extract(raster_obj, prison_obj, fun = "mean", na.rm = TRUE)) %>% 
      unnest(cols = wildfire_risk) %>% 
      select(!ID) %>% 
      rename("wildfire_risk" = names(raster_obj))
    
    return(df)
    
  }
  
  
  
  # Blazing fast with dplyr
  prisons_conus_wf <- wfRiskCalc(prisons_conus, wf_conus)
  
  prisons_ak_wf <- wfRiskCalc(prisons_ak, wf_ak)
  
  prisons_hi_wf <- wfRiskCalc(prisons_hi, wf_hi)
  
  
  # Resultant wildfire calculation dataset
  prisons_wf <- bind_rows(prisons_conus_wf, prisons_ak_wf, prisons_hi_wf) %>% 
    dplyr::select(FACILITYID, wildfire_risk)
  
  
  if (save == TRUE){
    
    write_csv(prisons_wf, file = paste0(path,"/prisons_wildfire_", date, ".csv"))
  }
  
  
  
}