# experiment with heat risk calculation from MODIS LST

library(tidyverse)
library(sf)
library(terra)
library(tmap)

# read in prisons
prisons <- read_sf("data/processed/study_prisons.shp") %>% 
  st_transform(crs = 4326)


# inspect polygon calculation from GEE
prison_lst_stats <- read_csv("data/processed/prison_modis_temp_stats.csv")

#crap, this averaged across ALL polygons,  not each polygon individually


# read in LST output raster
modis <- terra::rast("data/processed/modis_lst.tif")

#DONT' USE THIS ONE
modis2 <- terra::rast("data/processed/modis_lst-23296.tif") # the lat/long here are swapped


# examine value dist of modis
freq(modis)

# this only shows 2460 pixels with values....


# buffer prisons
prison_buff <- st_buffer(prisons, dist = 5000)



# calculate modis values w/in prisons
prison_buff$heat_risk <- terra::extract(modis, prison_buff, fun = "mean", na.rm = TRUE)[,2]

#plot it out
tmap_mode("view")


qtm(prison_buff, symbols.col = "heat_risk")
# This looks correct...but lots of NAs
prison_buff %>% filter(is.na(heat_risk))
# 133 NAs ....
