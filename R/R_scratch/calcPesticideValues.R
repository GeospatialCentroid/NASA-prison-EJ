# Function to calculate usage values (kg/ha-year) from a subset of SEDAC (PEST-CHEMGRIDS). 
# Usage values (~100ha grid) will then be correlated with prison polygons.

# Input should be filtered files from getPesticides.R

# SEDAC dataset: https://sedac.ciesin.columbia.edu/data/set/ferman-v1-pest-chemgrids-v1-01
# CalEnviroScreen list: https://oehha.ca.gov/media/downloads/calenviroscreen/report/calenviroscreen40reportf2021.pdf [Pages 79 - 90]


# File Created: February 15, 2023

library(tidyr)
library(dplyr)
library(terra)
library(sf)
library(stringr)

calcPesticideValues <- function(pesticide_cal_sedac_filenames){
  
  # Iterating over each pair of pesticide / crop to calculate mean values
  for (index in seq(1, (length(pesticide_cal_sedac_filenames$filename)), 2)) {
    
    # Load the two corresponding High and Low estimate rasters
    rast_H <- terra::rast(pesticide_cal_sedac_filenames$filename[index])
    rast_L <- terra::rast(pesticide_cal_sedac_filenames$filename[index + 1])
    
    # Replace negative values with NA
    rast_H[rast_H < 0] <- NA
    rast_L[rast_L < 0] <- NA
    
    # Create a corresponding filename for export
    stripped_filename <- stringr::word(pesticide_cal_sedac_filenames$filename[index], start = 3L, end = 5L, sep = "_")
    out_filename <- paste0("data/processed/pesticide_sedac/average/", stripped_filename, "_AVG.tif")
    
    # Calculate mean from High and Low estimate
    pesticide_mean <- mosaic(x = rast_H, y = rast_L, fun = "mean", 
                             filename = out_filename, 
                             overwrite = TRUE)
    
  }

  pest_sedac_files <- list.files("data/processed/pesticide_sedac/average/",
                                 full.names = TRUE,
                                 no.. = TRUE)
  
  pest_collection <- sprc(pest_sedac_files)
  
  # Add overlapping values of pesticides from collection
  pesticide_sum <- mosaic(pest_collection, fun = "sum", 
                          filename = "data/processed/pesticide_sedac/pesticides_sedac_2020.tif", 
                          overwrite = TRUE)
  
  return(pesticide_sum)
}


## TEST ----
test_call <- calcPesticideValues(test_getPesticides)

# Visualize Results
terra::plet(x = test_call,
     main = "Average Pesticide Use\nin 2020 (kg/ha-year)")

tmap::qtm(test_call)
