#' Calculate climate component scores
#'
#' This function runs all the functions to process climate component indicators, and in this case also reads in the
#' output data from the GEE scripts in the python/ folder
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param fire_file A file path pointing to the folder with the 3 wildfire raster layers
#' @param heat_risk_file A file path to the .csv output of heat risk for each facility from the python/calc_modis_lst.py script
#' @param canopy_cover_folder A file path to the folder/file that has the three csv outputs from the python/calc_canopy_cover.py script
#' @param flood_dist Buffer distance (m) to set for the calc_flood_risk() function. Default is 1000m.
#' @param fire_dist Buffer distance (m) to set for the calc_wildfire_risk() function. Default is 1000m.
#' @param conus_only Logical. If TRUE, skips AK and HI wildfire processing. Use when the input sf_obj
#'                   contains only CONUS facilities. Passed to calc_wildfire_risk(). Default is FALSE.
#' @param id_column A string specifying the name of the unique facility identifier column used across all datasets (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities). Default is "FACILITYID".
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each climate indicator and the climate component score
climate_component <-
  function(sf_obj,
           fire_file,
           heat_risk_file,
           canopy_cover_folder,
           flood_dist = 1000,
           fire_dist = 1000,
           conus_only = FALSE,
           id_column = "FACILITYID",
           save = TRUE,
           out_path = "outputs/") {
    
    ## FLOOD RISK -------------------------------
    flood_risk <- calc_flood_risk(
      sf_obj,
      dist = flood_dist,
      id_column = id_column,
      save = save,
      out_path = out_path
    )
    print("Flood Risk indicator calculated")
    
    ## WILDFIRE RISK -----------------------------
    wildfire_risk <- calc_wildfire_risk(
      sf_obj,
      file = fire_file,
      dist = fire_dist,
      conus_only = conus_only,
      id_column = id_column,
      save = save,
      out_path = out_path
    )
    print("Wildfire risk indicator calculated")
    
    ## HEAT RISK --------------------------------------
    
    # First process the raw daily LST files from calc_myd11_lst_day.py script
    lst_daily <- read_csv(heat_risk_file)
    
    # calculate total average across all days/years
    heat_risk <- lst_daily %>% 
      group_by(!!sym(id_column)) %>% 
      summarise(lst_avg = median(LST_mean, na.rm = TRUE))
    
    ## CANOPY COVER -----------------------------------
    
    # control for CONUS (single file) or not (folder with multiple files)
    if (str_detect(canopy_cover_folder, ".csv")) {
      canopy_cover <- read_csv(canopy_cover_folder)
    } else {
      canopy_cover <-
        list.files(canopy_cover_folder, pattern = ".csv", full.names = TRUE) %>%
        map_df(~ read_csv(.))
    }
    
    ## JOIN AND SCORE ---------------------------------
    
    df <-
      list(flood_risk, wildfire_risk, heat_risk, canopy_cover) %>%
      # convert id_column to character for all to make sure they join
      purrr::map(~ .x %>% mutate(!!sym(id_column) := as.character(!!sym(id_column)))) %>%
      purrr::reduce(left_join, by = id_column) %>%
      # calculate percentile columns for each raw indicator
      mutate(across(
        where(is.numeric),
        .fns = list(pcntl = ~ cume_dist(.) * 100),
        .names = "{col}_{fn}"
      )) %>%
      # need to inverse canopy cover since high value is good
      mutate(across(matches("canopy_cover|tree_cover", ignore.case = TRUE),
                    ~ cume_dist(desc(.)) * 100,
                    .names = "{.col}_pcntl")) %>%
      rowwise() %>%
      # calculate climate component score (average all indicator percentile values per facility)
      mutate(climate_score = gm_mean(c_across(contains("pcntl"))))
    
    
    if (save == TRUE) {
      write_csv(df, file = paste0(out_path, "/climate_component_", Sys.Date(), ".csv"))
      print(paste("Climate component data saved to", out_path))
    }
    
    return(df)
  }