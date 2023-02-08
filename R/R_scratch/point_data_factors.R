# Read in and process all point-data datasets

library(tidyverse)
library(sf)
library(furrr) #Parallel iterations for NPL geocoding

source("R/R_scratch/BufferCalculations.R")

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

# POWER PLANTS ---------------------------------------------------

# Studying the type and proximity of power plants

# Importing data
global_power <- read.csv("data/raw/power_plants/global_power_plant_database_v_1_3/global_power_plant_database.csv")

# Filter for non-renewable United States plants
us_power <- global_power %>% 
  filter(country == "USA",
         !primary_fuel %in% c("Solar", "Wind", "Hydro")) %>% 
  mutate(commissioning_year = as.integer(commissioning_year))

# Make spatial feature
us_power_sp <- us_power %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Counts how many total plants are within 1000m (1km) of each prison, and which plant
prisons$plants_1km <- st_is_within_distance(prisons, us_power_sp, dist = 1000)

# Filter for which plants, and distance from prison
prisons_power1km <- prisons %>% 
  unnest(plants_1km)

power_prison1km <- us_power_sp[prisons_power1km$plants_1km,]

# Running Buffer Function, creates similar output to power_prison_1km
power_prison_buffs <- BufferCalculation(us_power_sp, "power_plants")

# NPL SITES ---------------------------

# Read in NPL dataset
npl <- readr::read_csv("data/raw/npl_sites.csv", skip = 13) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_sub(zip_code, 2, 6))

# Experiment with geocoding, as many NA's produced
## Parallelize with 8 CPU cores
plan("multisession", workers = 8)

## Arcgis
npl_geo_address_df <- npl %>% 
  unite(full_address, c("street_address", "city", "state"), sep = ", ") %>%
  unite(full_address, c("full_address", "zip_code"), sep = " ") %>% 
  filter(!(epa_id  %in% c("AZD094524097", "MOD981507585"))) # remove rows with weird characters

# Prep address list to geocode using ArcGIS Method
npl_geo_address <- as.list(npl_geo_address_df$full_address)

# Furrr-powered geocoding call
npl_geo_arc <- future_map(.x = npl_geo_address,
                          ~ tidygeocoder::geo(address = .x, method = 'arcgis', lat = latitude , long = longitude, limit = 1)) %>% 
  bind_rows()


# Renaming and cleaning
npl_geo_arc <- npl_geo_arc %>% 
  rename("full_address" = "address")

npl_geo_arc_df <- npl_geo_address_df %>% 
  left_join(., npl_geo_arc, by = "full_address")


# remove NAs and set CRS ArcGIS
npl_geo_arc <- npl_geo_arc %>% 
  filter(!is.na(latitude) & !is.na(longitude)) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

write.csv(npl_geo_arc, "data/processed/npl_addresses_geocoded_arc.csv")

npl_prison_buffs <- BufferCalculation(npl_geo_arc, "national_priority_sites")

