# code base to run processing functions to calculate indicator scores

library(tidyverse)
library(sf)
library(terra)

#source all processing functions
lapply(list.files(
  path = "R/src/",
  pattern = ".R",
  full.names = TRUE
),
source)

# read in processed prison polygons
prisons <- read_sf("data/processed/study_prisons.shp")


# flood risk (takes 1-2 days to run, quite a few NAs too)
floodRisk <- getFloodRisk(prisons = prisons)


# wildfire risk
wildfireRisk <- getWildfireRisk(prisons = prisons)


# ozone
ozone <- getOzone(prisons, folder = "data/raw/air_quality/o3-us-1-km-2000-2016-annual/", 
                  dist = 1000, years = c(2015, 2016), save = TRUE)


# pm2.5 (may change dataset, check for more recent years)
pm25 <- getPM25(prisons, folder = "data/raw/air_quality/pm2-5-us-1-km-2000-2016-annual/", 
                dist = 1000, years = c(2015, 2016), save = TRUE)


# pesticides (ran this manually to save time re-creating all rasters)
pesticides <- calcPesticides(prisons, dist = 1000, save = TRUE)


# traffic proximity (takes 1.5 days to run on Desktop comp)
trafficProx <- getTrafficProximity(prisons = prisons, file = "data/processed/traffic_proximity/aadt_2018.RData",
                                   save = TRUE, path = "data/processed/")
