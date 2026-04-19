#load in packages
source("setup.R")
library(mapview)

#path to zillow data
zillow_path <- "data/scratch/Zillow_Neighborhoods/ZillowNeighborhoods.gdb"

#look at the layers
st_layers(zillow_path)

#let's look at the neighborhood areas, and geoDD to understand the difference
zillow_geodd <- st_read(zillow_path,layer="ZillowNeighborhoods_GeoDD")
zillow_areas <- st_read(zillow_path,layer="ZillowNeighborhoodsAreas")

#do these look cool?
mapview(zillow_geodd) #they seem to be the same? hmm. All polygon data
mapview(zillow_areas)
