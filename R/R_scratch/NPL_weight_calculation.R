# Environmental Weight calculation function for National Priority List Sites.
# Scale ranges from 0 - 12, 12 being the highest environmental impact.
# Environmental Weight Calculation is used as a multiplier with the buffer_calculation function
# Values from: https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf, pg. 111

NPL_weight_calculation <- function(NPL_data){
  # SITE TYPE
  NPL_site <- NPL_data %>% 
    mutate(site_type = dplyr::case_when())
  
  
  
  
  
  
  
}











