# this is a job script to calculate the environmental effects component as a background job


# set up environment -----------------
source("setup.R")

# read in processed facility polygons/points
ice <- read_sf("data/ice/ice_detention_facilities.gpkg")


effects_scores <- effects_component(
  sf_obj    = ice,
  rmp_file  = "data/phase2/raw/RMP/EPA RMP Spreadsheets — The Data Liberation Project - Facilities.csv",
  npl_file  = "data/phase2/processed/NPL/NPL_arc_geocode.shp",
  haz_file  = "data/phase2/processed/hazardous_waste/TSD_LQGs.csv",
  rmp_dist  = 5000,
  npl_dist  = 5000,
  haz_dist  = 5000,
  id_column = "object_id",
  save      = TRUE,
  out_path  = "outputs/ice/"
)