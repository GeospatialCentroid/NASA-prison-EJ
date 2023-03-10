# code base to run processing functions to calculate indicator scores

library(tidyverse)
library(sf)
library(terra)



# read in processed prison polygons
prisons <- read_sf("data/processed/study_prisons.shp")


source("R/src/getFloodRisk.R")


floodRisk <- getFloodRisk(prisons = prisons)


