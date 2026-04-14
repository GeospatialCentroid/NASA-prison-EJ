#' Calculate traffic proximity
#'
#' This function calculates a traffic proximity score using the FHA's Annual Average Daily Traffic for
#' 2023. The score is calculated by the AADT for major roads within 500m of the prison boundaries,
#' and weights them by dividing the AADT value by the nearest distance from the prison.
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param file The filepath to the .RData file for the 2023 U.S. AADT shapefile. See 'process_traffic.R' script for how this was processed
#' @param dist The buffer distance (in meters) to add around polygon boundaries. Default is 500m.
#' @param workers Number of parallel workers. Defaults to all available cores minus 1.
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with traffic proximity scores for each buffered polygon boundary
calc_traffic_proximity <-
  function(sf_obj,
           file,
           dist = 500,
           workers = parallel::detectCores() - 1,
           save = TRUE,
           out_path = "outputs/") {
    
    library(furrr)
    library(future)
    
    # RData loads faster than .gpkg, so just make sure object name matches
    load(file)
    
    #clean up aadt_2023 for quicker crop step
    aadt_2023 <- aadt_2023 %>%
      filter(!st_is_empty(st_geometry(.))) %>% 
      select(ROUTEID, AADT, F_SYSTEM)
    
    # set attribute constant argument to suppress sf warning w/ st_crop
    st_agr(aadt_2023) <- "constant"
    
    # disable s2 to avoid geometry parse errors
    sf_use_s2(FALSE)
    on.exit(sf_use_s2(TRUE))
    
    # project prisons to EPSG:5070 for accurate buffering/distance in meters
    sf_proj <- st_transform(sf_obj, 5070)
    
    message("Buffering all prisons and building spatial index...")
    
    # buffer all prisons at once
    all_buffers <- st_buffer(sf_proj, dist)
    
    # pre-compute spatial index: candidate road indices per prison in one pass
    # this replaces 1900 individual st_crop calls with a single spatial join
    candidates <- st_intersects(all_buffers, aadt_2023)
    
    message(sprintf(
      "Spatial index built. Running scoring for %d facilities on %d workers...",
      nrow(sf_proj), workers
    ))
    
    # set up parallel backend
    plan(multisession, workers = workers)
    on.exit(plan(sequential), add = TRUE)
    
    # score each prison in parallel
    traffic_scores <- future_map(
      1:nrow(sf_proj),
      function(i) {
        
        idx <- candidates[[i]]
        
        # no roads within buffer
        if (length(idx) == 0) {
          return(tibble(
            FACILITYID = sf_proj[i, ]$FACILITYID,
            trafficProx = 0
          ))
        }
        
        roads_crop <- aadt_2023[idx, ]
        
        # guard against missing AADT column
        if (!"AADT" %in% names(roads_crop)) {
          return(tibble(
            FACILITYID = sf_proj[i, ]$FACILITYID,
            trafficProx = 0
          ))
        }
        
        prison_i <- sf_proj[i, ]
        
        roads_scored <- roads_crop %>%
          mutate(AADT = as.numeric(AADT)) %>%
          filter(!is.na(AADT)) %>%
          # calculate each segment's distance to prison polygon
          mutate(distance = as.numeric(st_distance(st_geometry(.), prison_i))) %>%
          # for each route ID, keep highest AADT then break ties by min distance
          group_by(ROUTEID) %>%
          slice_max(AADT, n = 1, with_ties = TRUE) %>%
          slice_min(distance, n = 1, with_ties = FALSE) %>%
          ungroup() %>%
          mutate(score = AADT / pmax(distance, 1)) # guard against distance = 0
        
        tibble(
          FACILITYID = prison_i$FACILITYID,
          trafficProx = sum(roads_scored$score)
        )
      },
      .options = furrr_options(
        globals = list(aadt_2023 = aadt_2023, sf_proj = sf_proj, candidates = candidates),
        packages = c("dplyr", "sf"),
        seed = NULL
      ),
      .progress = TRUE
    )
    
    # bind all prison traffic scores
    traffic_prox <- bind_rows(traffic_scores)
    
    if (save == TRUE) {
      write_csv(traffic_prox, file = paste0(out_path, "/traffic_proximity_", Sys.Date(), ".csv"))
    }
    
    return(traffic_prox)
  }