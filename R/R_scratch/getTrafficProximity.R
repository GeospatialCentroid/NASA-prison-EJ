# scratch workflow for calculating traffic proximity indicator
# workflow: find all segments within 500m, divide each by distance and multiply by aadt

library(tidyverse)
library(sf)
library(tmap)

tmap_mode("view")



prisons <- read_sf("data/processed/study_prisons.shp")


load("data/processed/traffic_proximity/aadt_2018.RData")

#convert traffic to crs of prisons
aadt_2018_prj <- st_transform(aadt_2018, st_crs(prisons))



prison_traffic <- prisons[1,] %>% 
  mutate(roads_buffer = st_is_within_distance(prisons[1,], aadt_2018_prj, dist = 500))

#retrive segments within 500m
segments <- aadt_2018_prj[unlist(prison_traffic$roads_buffer),]

qtm(st_buffer(prison_traffic, 500))

# try buffer and st_intersect instead
buff <- st_buffer(prisons[1,], 500) %>% 
  mutate(segments_500m = st_intersects(., aadt_2018_prj))


segments2 <- aadt_2018_prj[unlist(buff$segments_500m),]
