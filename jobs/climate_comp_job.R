# this is a job script to calculate the climate sensitivity component as a background job


# set up environment -----------------
source("setup.R")

# read in processed facility polygons/points
ice <- read_sf("data/ice/ice_detention_facilities.gpkg")


climate_scores <- climate_component(
  sf_obj               = ice,
  fire_file            = "data/phase2/raw/wildfire_risk/Data/whp2023_GeoTIF/",
  heat_risk_file       = "data/ice/ice_lst_daily_MODIS_2026-05-19.csv",
  canopy_cover_folder  = "data/ice/ice_canopy_2026-05-19.csv",
  flood_dist           = 1000,
  fire_dist            = 1000,
  conus_only           = TRUE,
  id_column            = "object_id",
  save                 = TRUE,
  out_path             = "outputs/ice/"
)