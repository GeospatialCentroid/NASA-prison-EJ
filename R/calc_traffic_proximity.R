#' Calculate traffic proximity
#'
#' This function calculates a traffic proximity score using the FHA's Annual Average Daily Traffic for
#' 2018. The score is calculated by the AADT for major roads within 500m of the prison boundaries,
#' and weights them by dividing the AADT value by the nearest distance from the prison.
#'
#' @param sf_obj An sf object of all polygons to be assessed
#' @param file The filepath to the .RData file for the 2018 U.S. AADT shapefile. See 'process_traffic.R' script for how this was processed
#' @param dist The buffer distance (in meters) to add around polygon boundaries. Default is 500m.
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param out_path If `save = TRUE`, the file path to save the dataframe.
#'
#' @return A tibble with traffic proximity scores for each buffered polygon boundary
calc_traffic_proximity <-
  function(sf_obj,
           file,
           dist = 500,
           save = TRUE,
           out_path = "outputs/") {
    load(file)

    # set attribute constant argument to suppress sf warning w/ st_crop
    st_agr(aadt_2018) <- "constant"

    # make an empty list
    traffic_scores <- vector("list", length = nrow(sf_obj))

    for (i in 1:nrow(sf_obj)) {
      # if no 'major' roads within 500m
      if (nrow(st_crop(aadt_2018, st_buffer(sf_obj[i, ], 500))) == 0) {
        traffic_scores[[i]] <- tibble(
          FACILITYID = sf_obj[i, ]$FACILITYID,
          trafficProx = 0
        )
      } else {
        # crop
        roads_crop <-
          st_crop(aadt_2018, st_buffer(sf_obj[i, ], 500)) %>%
          # group by unique aadt values, assuming these indicate distinct roads
          group_by(aadt) %>%
          # calculate closest distance from road to prison
          summarise(distance = min(st_distance(., sf_obj[i, ]))) %>%
          ungroup() %>%
          mutate(score = aadt / distance)

        # return traffic score tied to prison FACILITY ID
        traffic_scores[[i]] <-
          tibble(
            FACILITYID = sf_obj[i, ]$FACILITYID,
            trafficProx = sum(as.numeric(roads_crop$score))
          )
      }

      print(i)
    }


    # bind all prison traffic scores
    traffic_prox <- bind_rows(traffic_scores)


    if (save == TRUE) {
      write_csv(traffic_prox, file = paste0(path, "/traffic_proximity_", Sys.Date(), ".csv"))
    }


    return(traffic_prox)
  }
