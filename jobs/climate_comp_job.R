# this is a job script to calculate the climate sensitivity component as a background job


# set up environment -----------------
source("setup.R")

# read in processed facility polygons/points
ice <- read_sf("data/ice/ice_detention_facilities.gpkg")

# Use parameters from exported environment if available, otherwise use defaults
flood_dist <- if (exists("climate_params")) climate_params$flood_dist else 1000
fire_dist  <- if (exists("climate_params")) climate_params$fire_dist else 1000

climate_scores <- climate_component(
  sf_obj = ice,
  fire_file = "data/phase2/raw/wildfire_risk/Data/whp2023_GeoTIF/",
  heat_risk_file = "data/ice/ice_lst_daily_MODIS_2026-05-19.csv",
  canopy_cover_folder = "data/ice/ice_canopy_2026-05-19.csv",
  flood_dist = flood_dist,
  fire_dist = fire_dist,
  id_column = "object_id",
  save = TRUE,
  out_path = "outputs/ice/"
)