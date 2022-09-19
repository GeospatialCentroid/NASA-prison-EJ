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

