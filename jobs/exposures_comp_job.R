# this is a job script to calculate the environmental exposures component as a background job


# set up environment -----------------
source("setup.R")

# read in processed facility polygons/points
ice <- read_sf("data/ice/ice_detention_facilities.gpkg")

# Use parameters from exported environment if available, otherwise use defaults
pm25_dist      <- if (exists("exposures_params")) exposures_params$pm25_dist      else 1000
pesticide_dist <- if (exists("exposures_params")) exposures_params$pesticide_dist else 0
traffic_dist   <- if (exists("exposures_params")) exposures_params$traffic_dist   else 500

exposures_scores <- exposures_component(
  sf_obj           = ice,
  ozone_folder     = "data/phase2/raw/ozone/",
  pm25_folder      = "data/phase2/raw/air_quality/pm2.5_sedac/",
  pesticide_folder = "data/phase2/raw/pesticides/ferman-v1-pest-chemgrids-v1-01-geotiff",
  traffic_file     = "data/processed/traffic_proximity/aadt_2023.RData",
  pm25_dist        = pm25_dist,
  pesticide_dist   = pesticide_dist,
  traffic_dist     = traffic_dist,
  id_column        = "object_id",
  save             = TRUE,
  out_path         = "outputs/ice/"
)