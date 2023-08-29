# Pull FEMA flood hazard from ArcGIS Rest services

library(sf)
library(tmap)
library(tidyverse)


# make st_bbox

## test w/ foco area
bb <- st_bbox(c(xmin = -105.89218, ymin = 40.27989, xmax = -105.17284, ymax = 40.72316), crs = st_crs(4326))


# extract bbox
bb.ordered <- paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")


# choose layer
layer <- 28

# construct URL
url <- paste0(
  "https://hazards.fema.gov/gis/nfhl/rest/services/public/",
  "NFHL/MapServer/",
  layer,
  "/query?",
  "&geometry=",
  bb.ordered,
  "&geometryType=esriGeometryEnvelope",
  "&outFields=*",
  "&returnGeometry=true",
  "&returnZ=false",
  "&returnM=false",
  "&returnExtentOnly=false",
  "&f=geoJSON"
)



floodHaz <- sf::read_sf(url)

# Enviroscreen method: 'ZONE_SUBTY' == 'FLOODWAY', areas that have a 1% chance of flooding annually
floodRisk1 <- floodHaz %>%
  filter(ZONE_SUBTY == "FLOODWAY")
# this only includes 19 features in Larimer county...

# filter to zones that hve A or V in them - high-risk flood zones/1% flood prob https://floodpartners.com/flood-zones/
floodRisk2 <- floodHaz %>%
  filter(stringr::str_detect(FLD_ZONE, "A|V") & FLD_ZONE != "AREA NOT INCLUDED") # not sure if 'area not included' is in fema raw data


# compare to Enviroscreen data:
floodHazCO <- read_sf("L:/Projects_active/EnviroScreen/data/floodPlains/floodHazard.shp")

test1 <- floodHazCO %>%
  filter(ZONE_SUBTY == "FLOODWAY")

test2 <- floodHazCO %>%
  filter(stringr::str_detect(FLD_ZONE, "A|V") & FLD_ZONE != "AREA NOT INCLUDED")


# workflow, base off getFloodplain
# read in prison boundaries
# buffer
# each one, extract bbox, read in fema data
# intersect floodRisk layer w/ prinson boundary + prison boundary buffer
# calculate area
# calculate percent covering prison boundary

# figure out fastest way to read in FEMA layer (all at once doesn't work, too big)


# read in study prisons

prisons <- read_sf("data/processed/study_prisons.shp") %>%
  # transform to 4WGS84 to match floodplains
  st_transform(crs = 4326)


# get unique facility IDs
prisonID <- unique(prisons$FACILITYID)


# df for presence of floodplains
df <- tibble(
  FACILITYID = character(),
  flood_risk_area_m2 = numeric(),
  flood_risk_percent = numeric()
)

# for each prison....
for (i in 1:length(prisonID)) {
  df[i, "FACILITYID"] <- prisonID[i]

  boundary <- prisons %>%
    filter(FACILITYID == prisonID[i])

  ## buffer prison
  prison_buffer <- st_buffer(boundary, 5000)


  ## get bounding box
  bb <- st_bbox(prison_buffer)

  ## extract bbox
  bb.ordered <- paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")

  ## construct URL
  url <-
    paste0(
      "https://hazards.fema.gov/gis/nfhl/rest/services/public/",
      "NFHL/MapServer/",
      28,
      "/query?",
      "&geometry=",
      bb.ordered,
      "&geometryType=esriGeometryEnvelope",
      "&outFields=*",
      "&returnGeometry=true",
      "&returnZ=false",
      "&returnM=false",
      "&returnExtentOnly=false",
      "&f=geoJSON"
    )


  ## read in floodplain
  floodHaz <- sf::read_sf(url)



  # if no flood zones
  if (nrow(floodHaz) == 0) {
    df[i, "flood_risk_area_m2"] <- 0
    df[i, "flood_risk_percent"] <- 0
  } else {
    ## filter to zones that have A or V in them - high-risk flood zones/1% flood prob https://floodpartners.com/flood-zones/
    floodRisk <- floodHaz %>%
      filter(stringr::str_detect(FLD_ZONE, "A|V") &
        FLD_ZONE != "AREA NOT INCLUDED") # not sure if 'area not included' is in fema raw data


    # if no high risk flood zones
    if (nrow(floodRisk) == 0) {
      df[i, "flood_risk_area_m2"] <- 0
      df[i, "flood_risk_percent"] <- 0
    } else {
      floodArea <- st_intersection(floodRisk, prison_buffer)

      # if no intersection
      if (nrow(floodArea) == 0) {
        df[i, "flood_risk_area_m2"] <- 0
        df[i, "flood_risk_percent"] <- 0
      } else {
        df[i, "flood_risk_area_m2"] <- as.numeric(sum(st_area(floodArea)))
        df[i, "flood_risk_percent"] <-
          as.numeric(sum(st_area(floodArea)) / st_area(prison_buffer) * 100)
      }
    }
  }
}


# test pulling entire file for CONUS
prisons_conus <- prisons %>%
  filter(!(STATE %in% c("HI", "AK")))


## get bounding box
bb <- st_bbox(prisons_conus)

## extract bbox
bb.ordered <- paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")

## construct URL
url <-
  paste0(
    "https://hazards.fema.gov/gis/nfhl/rest/services/public/",
    "NFHL/MapServer/",
    28,
    "/query?",
    "&geometry=",
    bb.ordered,
    "&geometryType=esriGeometryEnvelope",
    "&outFields=*",
    "&returnGeometry=true",
    "&returnZ=false",
    "&returnM=false",
    "&returnExtentOnly=false",
    "&f=geoJSON"
  )


## read in floodplain
floodConus <- sf::read_sf(url)
# still doesn't work..

url2 <-
  paste0(
    "https://hazards.fema.gov/gis/nfhl/rest/services/public/",
    "NFHL/MapServer/",
    28,
    "/query?",
    "&geometry=",
    "&geometryType=esriGeometryEnvelope",
    "&outFields=*",
    "&returnGeometry=true",
    "&returnZ=false",
    "&returnM=false",
    "&returnExtentOnly=false",
    "&f=geoJSON"
  )

floodRiskAll <- sf::read_sf(url2)

# read in from floodplain gdb --------------------------------------------

# this still takes a very long time....
rgdal::ogrListLayers("data/raw/floodPlains/NFHL_Key_Layers.gdb")

floodplains <- read_sf("data/raw/floodPlains/NFHL_Key_Layers.gdb", layer = "S_FLD_HAZ_AR")
