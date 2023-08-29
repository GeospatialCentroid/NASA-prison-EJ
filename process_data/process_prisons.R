# code to process raw prison boundary data to study sites

library(sf)
library(tidyverse)


prisons <- read_sf("data/raw/prisons/Prison_Boundaries.shp") %>% 
  #filter out just state and federal
  filter(TYPE %in% c("STATE", "FEDERAL")) %>% 
  #filter just U.S. (not territories)
  filter(COUNTRY == "USA") %>% 
  # filter out prisons with 0 or NA population and that are designated as "closed"
  filter(POPULATION > 0) %>% filter(STATUS == "OPEN")


write_sf(prisons, 'data/processed/prisons/study_prisons.shp')


#FYI looks like there are some prisons w/ dup names, so use facility IDs
prisons %>% 
  group_by(NAME) %>% 
  summarize(n = n()) %>% 
  filter(n > 1)


# create prison centroid point dataset and save as .csv
prisons %>% 
  st_transform(crs = 4326) %>% 
  st_centroid() %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2))) %>%
  st_drop_geometry() %>% 
  select(FACILITYID, NAME, long, lat) %>% 
  write_csv("data/processed/prisons/prison_centroids.csv")

# Write prisons in 4326 to use in GEE
st_read("data/processed/prisons/study_prisons.shp") %>% 
  st_transform(crs = 4326) %>% 
  write_sf("data/processed/prisons/study_prisons_4326.shp")
