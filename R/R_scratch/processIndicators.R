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


# flood risk
floodRisk <- getFloodRisk(prisons = prisons)


#wildfire risk
wildfireRisk <- getWildfireRisk(prisons = prisons)

