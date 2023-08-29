# this is a job script to calculate the environmental exposures component as a background job


# set up environment -----------------
source("setup.R")

# read in processed prison polygons
prisons <- read_sf("data/processed/prisons/study_prisons.shp")


exposures_scores <- exposures_component(prisons = prisons, 
                                        ozone_folder = "data/raw/air_quality/o3_daily/",
                                        pm25_folder = "data/raw/air_quality/pm2.5_sedac/",
                                        pesticide_folder = "data/raw/pesticides/ferman-v1-pest-chemgrids-v1-01-geotiff",
                                        traffic_file = "data/processed/traffic_proximity/aadt_2018.RData",
                                        save = TRUE, 
                                        out_path = "outputs/")