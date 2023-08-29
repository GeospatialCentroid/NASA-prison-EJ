# this is a job script to calculate the environmental effects component as a background job


# set up environment -----------------
source("setup.R")

# read in processed prison polygons
prisons <- read_sf("data/processed/prisons/study_prisons.shp")


effects_scores <- effects_component(prisons = prisons, 
                                    rmp_file = "data/raw/EPA_RMP/EPA_Emergency_Response_(ER)_Risk_Management_Plan_(RMP)_Facilities.csv",
                                    npl_file = "data/processed/npl_addresses_geocoded_arc_sf.csv",
                                    haz_file = "data/processed/hazardous_waste/TSD_LQGs.csv",
                                    save = TRUE, out_path = "outputs/")