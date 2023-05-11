#' Get impaired streams
#' 
#' This function loads 303d status streams data from the EPA and calculates the count of
#' impaired streams around each prison. Score is weighed by number of impairments per stream.
#' 
#' @param prisons An sf object of all prison polygons to be assessed
#' @param filePath the file path pointing to the folder 303d stream shapefile
#' @param dist The buffer distance(s) (in meters) at which streams are counted
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param writePath If `save = TRUE`, the file path to the folder to save the output csv to.
#' 
#' @function `calcPrisonProximity()`. Workhorse function for counting nearby impaired to prisons
#' 
#' @return A tibble with total streams per buffer zone for each prison point.

library(tidyr)
library(dplyr)

library(sf)

source("R/R_scratch/calcPrisonProximity.R")

# Begin function
# impairedStreams <- function(prisons, filepath = '...', dist = c(100, 300, 500), save = TRUE, writePath = 'data/processed')


# Read in data ----
prisons <- st_read("data/Prison_Boundaries.shp") %>% 
  #filter out just state and federal
  filter(TYPE %in% c("STATE", "FEDERAL")) %>% 
  st_transform(4326) %>% 
  st_centroid() %>% 
  #filter just U.S. (not territories)
  filter(COUNTRY == "USA") %>% 
  # filter out prisons with 0 or NA population and that are designated as "closed"
  filter(POPULATION > 0) %>% filter(STATUS == "OPEN") %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2)))

impaired_pts <- st_read("data/raw/impaired_streams_303d/rad_303d_20150501/rad_303d_p.shp") %>% 
  st_geometry(4326)
st_crs(impaired_pts)
impaired_seg <- st_read("data/raw/impaired_streams_303d/rad_303d_20150501/rad_303d_l.shp")
impaired_poly <- st_read("data/raw/impaired_streams_303d/rad_303d_20150501/rad_303d_a.shp")

impaired_data <- foreign::read.dbf("data/raw/impaired_streams_303d/rad_303d_20150501/attgeo_303dcaussrce.dbf")

# impaired_data_sub <- impaired_data

# Attribute data
## Filter for toxic toxic, (not temp, turbidity)
## group_by each and count each reason for 303d
## Find nearby waterbodies, get count (and which)
## bind by type, multiply by reason


calcPrisonProximity(prisons, )



impared <- st_read("C:/Users/devin/Desktop/CSU/Geospatial Centroid/NASA-prison-EJ/data/raw/impaired_streams_303d/rad_303d_20150501/")


