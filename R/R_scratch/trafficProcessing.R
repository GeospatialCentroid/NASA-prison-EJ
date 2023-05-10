# working script to calculate traffic density indicator

library(tidyverse)
library(sf)
library(arcpullr)



#get string of state names to loop over
states <- state.name %>% 
  str_replace_all(" ", "") %>% 
  # remove Alaska (no access to this layer for some reason) and add District of Columbia
  subset(., . != "Alaska") %>% 
  c(., "District")


# retrieve data for each state, filter, and bind to create a single dataset

state_traffic <- vector("list", length = length(states))

for (i in 1:length(states)) {
  
  url <- paste0("https://geo.dot.gov/server/rest/services/Hosted/", states[i], "_2018_PR/FeatureServer/0")
  
  
  # read and filter state layer
  # From metadata (https://www.fhwa.dot.gov/policyinformation/hpms/fieldmanual/hpms_field_manual_dec2016.pdf)
  # f_system 1 - Interstate, 2 and 3 - Principal Arterial, 4 - Minor Arterial in urban areas only (NOT urban_code 99999, that is Rural)
  
  state_traffic[[i]] <- get_spatial_layer(url) %>% 
    filter(f_system %in% 1:3 | f_system == 4 & urban_code != 99999)
  
  
  print(i)
  
  
}

# in case there was an error, save the list object so far

save(state_traffic, file = "data/processed/traffic_proximity/state_traffic_list.RData")


aadt_2018 <- bind_rows(state_traffic)


# project to CRS of prisons for analysis
prisons <- read_sf("data/processed/study_prisons.shp")

aadt_2018 <- st_transform(aadt_2018, st_crs(prisons))

save(aadt_2018, file = "data/processed/traffic_proximity/aadt_2018.RData")

