# Weight calculation function for US Power Plants.
# Scale ranges from # - ##, ## being the highest environmental impact.
# Environmental Weight Calculation is used as a multiplier with the buffer_calculation function
# Values from: ??

power_weight_calculation <- function(dataset){
  # SITE TYPE
  dataset$site_type <- dataset %>% 
    mutate(dplyr::case_when(primary_fuel == "Gas" ~ ,
                            primary_fuel == "Oil" ~ ,
                            primary_fuel == "Coal" ~ ,
                            primary_fuel == "Biomass" ~ ,
                            primary_fuel == "Waste" ~ ,
                            primary_fuel == "Storage" ~ ,
                            primary_fuel == "Cogeneration" ~ ,
                            primary_fuel == "Geothermal" ~ ,
                            primary_fuel == "Petcoke" ~ ,
                            primary_fuel == "Nuclear" ~ ,
                            primary_fuel == "Other" ~ ,
                            NA ~ 0))
  
  
}