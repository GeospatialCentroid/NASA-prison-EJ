# Buffer calculation function. Uses prisons dataset to calculate the amount of features within buffer ranges
# Inputs are sf dataframes with point feature data in WGS 1984 (CRS = 4326), and a factor name
# Outputs a summarized list of FID and FACILITYID with a count of input_points, and facility point feature data


calcPrisonProximity <- function(prison_sf, input_points_sf, buffer_distances_list, factor_name){
  
  buffers <- buffer_distances_list
  
  for (i in 1:length(buffers)) {
    
    prison_sf <- prison_sf %>% 
      mutate(buffer_calc = st_is_within_distance(prison_sf, input_points_sf, dist = buffers[i]))
    
    # tmp_prisons[, ncol(tmp_prisons) + 1] <- cbind(tmp_prisons, buffer_calc)
    names(prison_sf)[ncol(prison_sf)] <- paste0(factor_name,"_within_", buffers[i],"m")
    
  }
  
  # Create stats df, keeping FID and FACILITYID
  prison_prox_sf <- prison_sf %>%
      rowwise() %>%
      mutate(across(.cols = starts_with(factor_name),
                       .fns = ~length(.x),
                       .names = "{col}"))
  
  # Return summary df
  return(prison_prox_sf)
}

# Test Call
test_buffers <- calcPrisonProximity(prisons, us_power_sf, c(1000, 5000, 10000, 20000), "power_plants")
