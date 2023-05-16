#' Calculate spatial objects within proximity to prison
#' 
#' This function spatially counts all objects within certain buffer distances around each prison boundary.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param proxFeatures An sf object of interest features to count
#' @param factor The name of factor to be counted i.e 'npl_sites'
#' @param buffer The buffer distance(s) (in meters) to add around prison boundaries
#' @param filePath the file path pointing to the folder of the proxFeatures
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param writePath If `save = TRUE`, the file path to the folder to save the output csv to.
#' 
#' @return A tibble of FID and FACILITYID with a count of proxFeatures within each boudary
calcPrisonProximity <- function(prisons, proxFeatures, factor, buffer, 
                                filePath = NULL, save = FALSE, writePath = NULL){
  
  # Correct coordinate reference system
  if(st_crs(prisons) != st_crs(proxFeatures)){
    st_set_crs(proxFeatures, st_crs(prisons))
  }
  
  
  running = data.frame()
  # Get features within buffer distances
  for (i in 1:length(buffer)) {
    prisons <- prisons %>% 
      mutate(buffer_calc = st_is_within_distance(prisons, proxFeatures, dist = buffer[i]))
    
    # Assign custom column names for buffer
    names(prisons)[ncol(prisons)] <- paste0(factor,"_within_", buffer[i],"m")
    
    # Convert length of proxFeatures to count
    prisons <- prisons %>%
      rowwise() %>%
      mutate(across(.cols = ends_with(paste0(buffer[i],"m")),
                    .fns = ~length(.x),
                    .names = "{col}_count")) %>% 
      ungroup()
      
    orig <- prisons[ncol(prisons)] %>% st_drop_geometry()
    if(i == 1){
      running <- orig
    }
    if(i > 1){
      count <- prisons[ncol(prisons)-2] %>% st_drop_geometry()
      
      running <- (running + count)
      
      new <- prisons[ncol(prisons)] %>% st_drop_geometry()
      
      corrected <- (orig - running)
      
      corrected[corrected < 0] <- 0
      
      prisons[ncol(prisons)] <- corrected
    }
    
  }
  
  if (save == TRUE){
    
    write_csv(prison_prox, file = paste0(writePath, "prisons_proximity.csv"))
  }
  
  return(prisons)
}

# prisons_t <- prisons %>% 
#   select(FACILITYID)
# 
# # Test Call
# test_buffers <- calcPrisonProximity(prisons_t, us_power_sf, 'power', c(1000, 5000, 10000, 20000, 40000))
