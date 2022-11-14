# Buffer calculation function. Uses known prisons dataset to calculate the amount of features within buffer ranges
# Inputs are sf dataframes with point feature data in WGS 1984 (CRS = 4326), and a factor name
# Outputs a summarized list of FID and FACILITYID with a count of input_points, and facility point feature data

#                       point dataset [sf], factor name for column naming [text]
BufferCalculation <- function(input_points, factor_name) {
  
  
  # Create temporary df to protect prisons
  tmp_prisons <- prisons
  
  # Run spatial calculations at wanted buffers
  tmp_prisons$in_1km <- st_is_within_distance(prisons, input_points, dist = 1000)
  tmp_prisons$in_5km <- st_is_within_distance(prisons, input_points, dist = 5000)
  tmp_prisons$in_10km <- st_is_within_distance(prisons, input_points, dist = 10000)
  tmp_prisons$in_20km <- st_is_within_distance(prisons, input_points, dist = 20000)
  
  
  # Create stats df, keeping FID and FACILITYID
  stats_only <- tmp_prisons %>%
    select(c(1:2,34:37)) %>% 
    rename_with(., ~sub("in", factor_name, .x))
  
  # Convert list of features to total count.
  summary <- stats_only %>% 
    rowwise() %>% 
    mutate(across(.cols = c(3:6),
                     .fns = ~length(.x),
                     .names = "{col}"))
  
  # Return summary df
  return(summary)
}


