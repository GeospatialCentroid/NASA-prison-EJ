#' Calculate wildfire risk
#'
#' This function calculates mean wildfire hazard potential within given the spatial boundaries + specified
#' buffer distance around each boundary. This function is designed to work for spatial objects that span CONUS,
#' AK and HI, as wildfire hazard potential data is shared separately for CONUS, AK and HI which have unique projections
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param file the file path pointing to the folder with the 3 wildfire raster layers
#' @param dist The buffer distance (in meters) to add around polygon boundaries
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to the folder to save the output csv to.
#'
#' @return A tibble with mean wildfire hazard potential for each spatial object
calc_wildfire_risk <- function(sf_obj,
                            file,
                            dist = 1000,
                            save = TRUE,
                            out_path = "outputs/") {
  # buffer spatial objects
  prison_buffer <- st_buffer(sf_obj, dist) %>%
    st_make_valid()
  
  
  # read in rasters from file
  ## process individual files for CONUS, AK and HI ----
  
  wf_conus <- rast(paste0(file, "whp2023_cnt_conus.tif"))
  wf_ak <- rast(paste0(file, "whp2023_cnt_ak.tif"))
  wf_hi <- rast(paste0(file, "whp2023_cnt_hi.tif"))
  
  
  # need to separate spatial file for conus, ak and hi and project to matching raster
  prisons_conus <- prison_buffer %>%
    filter(!(STATE %in% c("AK", "HI"))) %>%
    st_transform(st_crs(wf_conus))
  
  prisons_ak <- prison_buffer %>%
    filter(STATE == "AK") %>%
    st_transform(st_crs(wf_ak))
  
  prisons_hi <- prison_buffer %>%
    filter(STATE == "HI") %>%
    st_transform(st_crs(wf_hi))
  
  
  # Calculates each wildfire risk value within its boundary
  extract_risk <- function(prison_obj, raster_obj) {
    df <- prison_obj %>%
      mutate(wildfire_risk = terra::extract(raster_obj, prison_obj, fun = "mean", na.rm = TRUE)) %>%
      unnest(cols = wildfire_risk) %>%
      select(!ID) %>%
      rename("wildfire_risk" = names(raster_obj)) %>% 
      st_drop_geometry()
    
    return(df)
  }
  
  
  # Calculate values with `WfRiskCalc()`
  prisons_conus_wf <- extract_risk(prisons_conus, wf_conus)
  
  prisons_ak_wf <- extract_risk(prisons_ak, wf_ak)
  
  prisons_hi_wf <- extract_risk(prisons_hi, wf_hi)

  
  # Resultant wildfire calculation dataset
  prisons_wf <-
    bind_rows(prisons_conus_wf, prisons_ak_wf, prisons_hi_wf) %>%
    dplyr::select(FACILITYID, wildfire_risk)
  
  
  if (save == TRUE) {
    write_csv(prisons_wf,
              file = paste0(out_path, "/wildfire_risk_", Sys.Date(), ".csv"))
  }
}
