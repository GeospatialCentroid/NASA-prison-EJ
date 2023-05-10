#' Calculate traffic proximity
#' 
#' This function calculates a traffic proximity score using the FHA's Annual Average Daily Traffic for
#' 2018. The score is calculated by the AADT for major roads within 500m of the prison boundaries,
#' and weights them by dividing the AADT value by the nearest distance from the prison.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param file The filepath to the .RData file for the 2018 U.S. AADT shapefile
#' @param dist The buffer distance (in meters) to add around prison boundaries. Default is 500m.
#' @param save Whether to save the resulting dataframe (as .csv) or not.
#' @param path If `save = TRUE`, the file path to save the dataframe.
#' 
#' @return A tibble with total area and percent area flood risk zones cover the buffered prison boundary
getTrafficProximity <- function(prisons, file, dist = 500, save = FALSE, path = NULL){
  
  load(file)
  
  
  # make an empty list
  traffic_scores <- vector("list", length = 4)
  
  for (i in 1:4) {
    
    # if no 'major' roads within 500m
    if (nrow(st_crop(aadt_2018, st_buffer(prisons[i, ], 500))) == 0) {
      
      traffic_scores[[i]] <- tibble(FACILITYID = prisons[i, ]$FACILITYID,
                                    trafficProx = 0)
      
    } else {
      # crop
      roads_crop <-
        st_crop(aadt_2018, st_buffer(prisons[i, ], 500)) %>%
        # group by unique aadt values, assuming these indicate distinct roads
        group_by(aadt) %>%
        # calculate closest distance from road to prison
        summarise(distance = min(st_distance(., prisons[i, ]))) %>%
        ungroup() %>%
        mutate(score = aadt / distance)
      
      # return traffic score tied to prison FACILITY ID
      traffic_scores[[i]] <-
        tibble(FACILITYID = prisons[i, ]$FACILITYID,
               trafficProx = sum(as.numeric(roads_crop$score))
        )
      
      
    }
    
    print(i)
    
  }
  
  
  # bind all prison traffic scores
  trafficProx <- bind_rows(traffic_scores)
  
  return(trafficProx)
  
}