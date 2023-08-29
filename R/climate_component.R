#' Calculate climate component scores
#'
#' This function runs all the functions to process climate component indicators, and in this case also reads in the
#' output data from the GEE scripts in the python/ folder
#'
#' @param prisons An sf object of all prison polygons to be assessed
#' @param fire_file A file path pointing to the folder with the 3 wildfire raster layers
#' @param heat_risk_file A file path to the .csv output of heat risk for each prison from the python/calc_modis_lst.py script
#' @param canopy_cover_folder A file path to the folder that has the three csv outputs from the python/calc_canpoy_cover.py script
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with raw values and percentiles for each climate indicator and the climate component score
climate_component <-
  function(prisons,
           fire_file,
           heat_risk_file,
           canopy_cover_folder,
           save = TRUE,
           out_path = "outputs/") {
    
    # run climate indicator functions
    
    ## note flood risk takes a very long time (days) to process
    flood_risk <- calc_flood_risk(prisons, dist = 1000, out_path = out_path)

    print("Flood Risk indicator calculated")

    
    wildfire_risk <- calc_wildfire_risk(
      prisons,
      file = fire_file,
      out_path = out_path
    )

    print("Wildfire risk indicator calculated")


    # read in outputs from modis and canopy cover GEE scripts

    heat_risk <- read_csv(heat_risk_file)


    canopy_cover <-
      list.files(canopy_cover_folder, pattern = ".csv", full.names = TRUE) %>%
      map_df(~ read_csv(.))



    # join data frames and calculate climate component score

    df <-
      list(flood_risk, wildfire_risk, heat_risk, canopy_cover) %>%
      # convert FACILITYID to character for all to make sure they join
      purrr::map( ~ .x %>% mutate(FACILITYID = as.character(FACILITYID))) %>%
      purrr::reduce(left_join, by = "FACILITYID") %>%
      # calculate percentile columns for each raw indicator
      mutate(across(
        where(is.numeric),
        .fns = list(pcntl = ~ cume_dist(.) * 100),
        .names = "{col}_{fn}"
      )) %>%
      # need to inverse canopy cover since high value is good
      mutate(percent_tree_cover_pcntl = cume_dist(desc(percent_tree_cover)) * 100) %>%
      rowwise() %>%
      # calculate climate component score (average all indicator percentile values per prison
      mutate(climate_score = gm_mean(c_across(contains("pcntl"))))
    

    if (save == TRUE) {
      write_csv(df, file = paste0(out_path, "/climate_component_", Sys.Date(), ".csv"))

      print(paste("Climate component data saved to", out_path))
    }

    return(df)
  }
