#' Calculate traffic proximity
#'
#' This function calculates a traffic proximity score using the FHA's Annual Average Daily Traffic for
#' 2023. The score is calculated by the AADT for major roads within a buffer of the facility boundaries,
#' and weights them by dividing the AADT value by the nearest distance from the facility.
#'
#' @param sf_obj    An sf object of all polygons to be assessed
#' @param file      The filepath to the .RData file for the 2023 U.S. AADT shapefile.
#'                  See 'process_traffic.R' script for how this was processed
#' @param dist      The buffer distance (in meters) to add around polygon boundaries. Default is 500m.
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#' @param workers   Number of parallel workers. Defaults to all available cores minus 1.
#' @param save      Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path  If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with traffic proximity scores for each buffered polygon boundary
calc_traffic_proximity <-
  function(sf_obj,
           file,
           dist = 500,
           id_column = "FACILITYID",
           workers = parallel::detectCores() - 1,
           save = TRUE,
           out_path = "outputs/") {
    
    library(furrr)
    library(future)
    
    load(file)
    
    aadt_2023 <- aadt_2023 %>%
      filter(!st_is_empty(st_geometry(.))) %>% 
      select(ROUTEID, AADT, F_SYSTEM)
    
    st_agr(aadt_2023) <- "constant"
    
    sf_use_s2(FALSE)
    on.exit(sf_use_s2(TRUE))
    
    # project to EPSG:5070 for accurate buffering/distance in meters
    sf_proj <- st_transform(sf_obj, 5070)
    
    message("Buffering all facilities and building spatial index...")
    
    all_buffers <- st_buffer(sf_proj, dist)
    
    candidates <- st_intersects(all_buffers, aadt_2023)
    
    message(sprintf(
      "Spatial index built. Running scoring for %d facilities on %d workers...",
      nrow(sf_proj), workers
    ))
    
    plan(multisession, workers = workers)
    on.exit(plan(sequential), add = TRUE)
    
    traffic_scores <- future_map(
      1:nrow(sf_proj),
      function(i) {
        
        idx <- candidates[[i]]
        
        if (length(idx) == 0) {
          return(tibble(
            !!sym(id_column) := sf_proj[i, ][[id_column]],
            trafficProx = 0
          ))
        }
        
        roads_crop <- aadt_2023[idx, ]
        
        if (!"AADT" %in% names(roads_crop)) {
          return(tibble(
            !!sym(id_column) := sf_proj[i, ][[id_column]],
            trafficProx = 0
          ))
        }
        
        facility_i <- sf_proj[i, ]
        
        roads_scored <- roads_crop %>%
          mutate(AADT = as.numeric(AADT)) %>%
          filter(!is.na(AADT)) %>%
          mutate(distance = as.numeric(st_distance(st_geometry(.), facility_i))) %>%
          group_by(ROUTEID) %>%
          slice_max(AADT, n = 1, with_ties = TRUE) %>%
          slice_min(distance, n = 1, with_ties = FALSE) %>%
          ungroup() %>%
          mutate(score = AADT / pmax(distance, 1))
        
        tibble(
          !!sym(id_column) := facility_i[[id_column]],
          trafficProx = sum(roads_scored$score)
        )
      },
      .options = furrr_options(
        globals = list(aadt_2023 = aadt_2023, sf_proj = sf_proj, candidates = candidates,
                       id_column = id_column),
        packages = c("dplyr", "sf"),
        seed = NULL
      ),
      .progress = TRUE
    )
    
    traffic_prox <- bind_rows(traffic_scores)
    
    if (save == TRUE) {
      write_csv(traffic_prox, file = paste0(out_path, "/traffic_proximity_", Sys.Date(), ".csv"))
    }
    
    return(traffic_prox)
  }