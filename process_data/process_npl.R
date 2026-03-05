# NATIONAL PRIORITY LIST (NPL) SITES ----

library(tidyverse)
library(sf)
library(furrr) # Parallel iterations for NPL geocoding


# Read in NPL dataset
npl <- readr::read_csv("data/phase2/raw/NPL/npl_sites.csv", skip = 13) %>%
  janitor::clean_names() %>%
  mutate(zip_code = str_sub(zip_code, 2, 6))

## GEOCODING from NPL Addresses ----

# Experiment with geocoding, as many NA's produced
## Parallelize with 8 CPU cores
plan("multisession", workers = 8)

## Arcgis
npl_geo_address_df <- npl %>%
  unite(full_address, c("street_address", "city", "state"), sep = ", ") %>%
  unite(full_address, c("full_address", "zip_code"), sep = " ") 

# Prep address list to geocode using ArcGIS Method
npl_geo_address <- as.list(npl_geo_address_df$full_address)

# Furrr-powered geocoding call
npl_geo_arc <- future_map(
  .x = npl_geo_address,
  ~ tidygeocoder::geo(address = .x, method = "arcgis", lat = latitude, long = longitude, limit = 1)
) %>%
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
st_write(npl_arc_sf, "data/phase2/processed/npl_addresses_geocoded_arc_sf.csv")
