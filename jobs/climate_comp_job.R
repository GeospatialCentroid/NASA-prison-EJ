# this is a job script to calculate the climate sensitivity component as a background job


# set up environment -----------------
source("setup.R")

# read in processed prison polygons
prisons <- read_sf("data/processed/prisons/study_prisons.shp")


# calculate climate component
climate_scores <- climate_component(
  prisons = prisons,
  fire_file = "data/raw/wildfire/whp2020_GeoTIF/",
  heat_risk_file = "data/processed/heat_exposure/lst_average.csv",
  canopy_cover_folder = "data/processed/canopy_cover/",
  save = TRUE,
  out_path = "outputs/"
)