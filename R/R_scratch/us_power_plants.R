# Power Plants in United States ----
  
  ## INITIALIZE ----

library(tidyverse)
library(sf)
library(furrr) #Parallel iterations for NPL geocoding

source("R/R_scratch/buffer_calculation.R")
source("R/R_scratch/power_weight_calculation.R")

# Read in prison locations
prisons <- st_read("data/raw/Prison_Boundaries.shp") %>% 
  #filter out just state and federal
  filter(TYPE %in% c("STATE", "FEDERAL")) %>% 
  st_transform(4326) %>% 
  st_centroid() %>% 
  #filter just U.S. (not territories)
  filter(COUNTRY == "USA") %>% 
  # filter out prisons with 0 or NA population and that are designated as "closed"
  filter(POPULATION > 0) %>% filter(STATUS == "OPEN")

## POWER PLANTS ---------------------------------------------------

# Studying the type and proximity of power plants

# Importing data
global_power <- read.csv("data/raw/power_plants/global_power_plant_database_v_1_3/global_power_plant_database.csv")

# Filter for non-renewable United States plants
us_power <- global_power %>% 
  filter(country == "USA",
         !primary_fuel %in% c("Solar", "Wind", "Hydro")) %>% 
  mutate(commissioning_year = as.integer(commissioning_year))

# Make spatial feature
us_power_sf <- us_power %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Running Buffer Function, Apply weight based upon plant fuel type

power_prison_buffs <- buffer_calculation(us_power_sf, "power_plants")

power_prison_weight <- power_weight_calculation(us_power_sf)
