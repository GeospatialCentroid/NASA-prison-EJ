#' Calculate wildfire risk
#'
#' This function calculates mean wildfire hazard potential within given the spatial boundaries + specified
#' buffer distance around each boundary. This function is designed to work for spatial objects that span CONUS,
#' AK and HI, as wildfire hazard potential data is shared separately for CONUS, AK and HI which have unique projections.
#'
#' @param sf_obj    An sf object of all polygons to be assessed
#' @param file      The file path pointing to the folder with the 3 wildfire raster layers
#' @param dist      The buffer distance (in meters) to add around polygon boundaries. Default is 1000m.
#' @param conus_only Logical. If TRUE, skips AK and HI processing and only assesses CONUS facilities.
#'                   Use when the input sf_obj contains no AK or HI facilities, or when the AK/HI
#'                   raster files are unavailable. Default is FALSE.
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#' @param save      Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path  If `save = TRUE`, the file path to the folder to save the output csv to.
#'
#' @return A tibble with mean wildfire hazard potential for each spatial object
calc_wildfire_risk <- function(sf_obj,
                               file,
                               dist = 1000,
                               conus_only = FALSE,
                               id_column = "FACILITYID",
                               save = TRUE,
                               out_path = "outputs/") {
  
  # buffer spatial objects
  facility_buffer <- st_buffer(sf_obj, dist) %>%
    st_make_valid()
  
  # read in CONUS raster
  wf_conus <- rast(paste0(file, "whp2023_cnt_conus.tif"))
  
  # Calculates each wildfire risk value within its boundary
  extract_risk <- function(facility_obj, raster_obj) {
    df <- facility_obj %>%
      mutate(wildfire_risk = terra::extract(raster_obj, facility_obj, fun = "mean", na.rm = TRUE)) %>%
      unnest(cols = wildfire_risk) %>%
      select(!ID) %>%
      rename("wildfire_risk" = names(raster_obj)) %>%
      st_drop_geometry()
    
    return(df)
  }
  
  if (conus_only) {
    
    facilities_conus <- facility_buffer %>%
      st_transform(st_crs(wf_conus))
    
    facilities_wf <- extract_risk(facilities_conus, wf_conus) %>%
      dplyr::select(!!sym(id_column), wildfire_risk)
    
  } else {
    
    wf_ak <- rast(paste0(file, "whp2023_cnt_ak.tif"))
    wf_hi <- rast(paste0(file, "whp2023_cnt_hi.tif"))
    
    facilities_conus <- facility_buffer %>%
      filter(!(STATE %in% c("AK", "HI"))) %>%
      st_transform(st_crs(wf_conus))
    
    facilities_ak <- facility_buffer %>%
      filter(STATE == "AK") %>%
      st_transform(st_crs(wf_ak))
    
    facilities_hi <- facility_buffer %>%
      filter(STATE == "HI") %>%
      st_transform(st_crs(wf_hi))
    
    facilities_wf <-
      bind_rows(
        extract_risk(facilities_conus, wf_conus),
        extract_risk(facilities_ak, wf_ak),
        extract_risk(facilities_hi, wf_hi)
      ) %>%
      dplyr::select(!!sym(id_column), wildfire_risk)
  }
  
  if (save == TRUE) {
    write_csv(facilities_wf,
              file = paste0(out_path, "/wildfire_risk_", Sys.Date(), ".csv"))
  }
  
  return(facilities_wf)
}