# Create preliminary map for Google conf

library(sf)
library(terra)
library(tidyverse)
library(leaflet)


# read in prison locations
prisons <- st_read("data/Prison_Boundaries.shp") %>% 
  #filter out just state and federal
  filter(TYPE %in% c("STATE", "FEDERAL")) %>% 
  st_transform(4326) %>% 
  st_centroid() %>% 
  #filter just U.S. (not territories)
  filter(COUNTRY == "USA") %>% 
  # filter out prisons with 0 or NA population and that are designated as "closed"
  filter(POPULATION > 0) %>% filter(STATUS == "OPEN")


# read in wildfire risk (from L:/ drive)


wf_conus <- terra::rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_conus.tif")

wf_ak <- terra::rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_ak.tif") 

wf_hi <- terra::rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_hi.tif") 



# extract conus values from prisons
wf_conus <- project(wf_conus, vect(prisons))


prisons$wildfire <- terra::extract(wf_conus, vect(prisons))[,2]



#quick map
pal1 <- colorNumeric(palette = "viridis", domain = prisons$wildfire)

leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons,
                   #color = ~pal1(wildfire),
                   radius = ~log(wildfire),
                   stroke = FALSE, fillOpacity = 1)



# heat index (average number of days from May - Sept 2016 - 2021 in which daily
# high temp exceeded the 90th percentile of historical daily temperatures, at the county level)


heat_days <- read_csv("data/heat_days/data_181732.csv") %>% 
  group_by(State, County, CountyFIPS) %>% 
  dplyr::summarise(heat_index = mean(Value))

#get spatial county data to tie to points
counties <- tigris::counties()

county_heat_index <- counties %>% 
  mutate(CountyFIPS = paste0(STATEFP, COUNTYFP)) %>% 
  left_join(heat_days, by = "CountyFIPS") %>% 
  st_transform(st_crs(prisons))


prisons_hi <- prisons %>% 
  st_join(county_heat_index["heat_index"])



#quick plot
leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons_hi,
                   color = "red",
                   radius = ~sqrt(heat_index),
                   stroke = FALSE, fillOpacity = 1)




