# NATIONAL PRIORITY LIST (NPL) and Non-NPL SUPERFUND SITES ----

library(tidyverse)
library(sf)
library(furrr) # Parallel iterations for NPL geocoding

source("R/R_scratch/buffer_calculation.R")
source("R/R_scratch/NPL_weight_calculation.R")

# Read in NPL dataset
npl_super <- readr::read_csv("data/raw/superfund_npl_active_2023ver.csv", skip = 9) %>% 
  janitor::clean_names() %>% 
  mutate_all(~gsub("[^[:alnum:][:blank:]?&/\\-]", "", .)) %>% # Replace UTF-8 encoded characters with "a0"
  mutate_all(~gsub("a0", "", .)) # Replaces UTF-8 output with ""
  # mutate(zip_code = str_sub(zip_code, 2, 6))

# Dataset metadata:
# "npl_status" of "Final NPL" means active on NPL list. Currently 1336 according to EPA website.
# sum(str_count(npl_super$npl_status, "Final NPL")) outputs 1336, verifying data integrity


## GEOCODING from all Addresses ----

## Parallelize with 8 CPU cores
plan("multisession", workers = 8)

## Assemble the address for geocoding
npl_super_address_df <- npl_super %>% 
  unite(full_address, c("street_address", "city", "state"), sep = ", ") %>%
  unite(full_address, c("full_address", "zip_code"), sep = " ") 
  

## Furrr-powered geocoding call ----
npl_super_geo_arc <- furrr::future_map(.x = npl_super_address_list,
                          ~ tidygeocoder::geo(address = .x, method = 'arcgis', lat = latitude , long = longitude, limit = 1)) %>%
  bind_rows()



# Renaming for join
npl_geo_arc <- npl_geo_arc %>%
  rename("full_address" = "address")

# Join geocoded geometry to original dataframe, remove duplicates
npl_arc_df <- npl_geo_address_df %>%
  left_join(., npl_geo_arc, by = "full_address") %>%
  filter(!duplicated(.))

# remove NAs and set CRS to WGS 84, convert to sf_object
npl_arc_sf <- npl_arc_df %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Save geocoded simple features
st_write(npl_arc_sf, "data/processed/npl_addresses_geocoded_arc_sf.csv")


# Prep address list to geocode using ArcGIS Pro Geocoder
npl_super_address_list <- as.list(npl_super_address_df$full_address)

write.csv(npl_super_address_df, "data/processed/arcpro_to_geocode.csv")


## IMPORT ARCGIS PRO GEOCODING ----

npl_arcpro_df <- read.csv("data/processed/npl_super_arcpro_geocoded.csv", check.names=FALSE, row.names = 1)


# Clean and convert geometry to simple feature
npl_arcpro_sf <- npl_arcpro_df %>% 
  filter(!is.na(latitude) & !is.na(longitude)) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>% 
  select(!1)

st_write(npl_arcpro_sf, "data/processed/npl_super_geocoded_arcpro_sf.csv", append = FALSE)

## RUN BUFFER AND SITE WEIGHT
npl_prison_buffs <- buffer_calculation(npl_arcpro_sf, "npl_superfund_sites")

npl_weight_score <- npl_weight_calculation(npl_arcpro_sf)
