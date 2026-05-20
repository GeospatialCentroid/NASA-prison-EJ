# this is a job script to calculate the environmental exposures component as a background job


# set up environment -----------------
source("setup.R")

# read in processed facility polygons/points
ice <- read_sf("data/ice/ice_detention_facilities.gpkg")


exposures_scores <- exposures_component(
  sf_obj           = ice,
  ozone_folder     = "data/phase2/raw/ozone/",
  pm25_folder      = "data/phase2/processed/PM2.5",
  pesticide_folder = "data/phase2/raw/pesticide/PEST-CHEMGRIDS_v2/NC/",
  traffic_file     = "data/phase2/processed/traffic/aadt_2023.RData",
  pm25_dist      = 1000,
  pesticide_dist = 0,    # kept at 0; pesticide raster is ~5km resolution
  traffic_dist   = 500,
  id_column        = "object_id",
  save             = TRUE,
  out_path         = "outputs/ice/"
)