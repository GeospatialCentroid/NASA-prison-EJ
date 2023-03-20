# Using RSEI data 2.3.10 (2020) from the EPA 
# Methods on page 94 of CalEnviroScreen 4.0 Report

# Requesting download of RSEI data (Access granted to AWS storage)

# HAZARDOUS WASTE SITES ----

library(tidyverse)
library(sf)
library(furrr)



## Workflow:
# Obtain data from the EPA RSEI https://www.epa.gov/rsei/rsei-data-and-modeling
# Import rasters (810m resolution)
# Extract exposeure values using prison polygons / buffer.

## From the AWS S3 service:
# 14 = Conterminous US
# 24 = Alaska
# 34 = Hawaii


dir.create("data/raw/RSEI_waste")

temp_gz <- tempfile()
gz_direct <- paste0(temp_gz, ".gz")

download.file("http://abt-rsei.s3.amazonaws.com/aggmicro2020/aggmicrocore012020_2020_gc14.csv.gz", 
              destfile = "data/raw/rsei_conus.gz")

rsei_us <- vroom::vroom("data/raw/rsei_conus.gz", col_names = FALSE)

colnames(rsei_us) <- c("grid_x", "grix_y", "num_facilities", "num_releases", "num_chemicals", "toxic_conc", "score", "population", "score_cancer", "score_non.cancer")

rsei_us$cell_code <- paste0(grid_x, grid_y)

shp_direct <- paste0(temp_shp, "rsei.shp")

conus_bot_links <- c("https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc14_conus_810m_bottom.dbf",
                          "https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc14_conus_810m_bottom.prj",
                          "https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc14_conus_810m_bottom.shp",
                          "https://gaftp.epa.gov/rsei/Shapefiles/810m_Standard_Grid_Shapefiles/poly_gc14_conus_810m_bottom.shx")

# filename <- stringr::word(conus_bot_links[1], start = -1, sep = "/")

for (link in conus_bot_links) {
  
  filename <- stringr::word(link, start = -1, sep = "/")
  
  filename_dir <- paste0("data/raw/RSEI_waste/", filename)
  
  rsei_us_bot_shp <- download.file(link,
                                   destfile = filename_dir,
                                   method = "curl")
}


rsei_us_bot_sf <- read_sf("data/raw/RSEI_waste/poly_gc14_conus_810m_bottom.shp")


rsei_us_bot_bind <- left_join()

