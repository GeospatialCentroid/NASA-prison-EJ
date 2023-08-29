# Wildfire Risk from prison polygons ----
# File Created: Jan 30, 2023, Devin Hunt

## INITIALIZE ----

library(tidyr)
library(dplyr)
library(terra)
library(stars)
library(sf)
library(leaflet)

# source("R/R_scratch/" raster calculation)

# Workflow
# -For loop {
#   -Get Prison polygon + 1km buffer
#   -Create SF bounding box
#   -Arcpullr image server "get_image_layer()", using SF bbox
#   -Calculate Statistics
#   -Append wildfire stat (%) to original wildfire data.frame
#   -Repeat until finished
# }

## IMPORT LOCAL DATA ----

### Prisons polygon data ----
prisons <- read_sf('data/processed/study_prisons.shp') %>% 
  st_transform(crs = 4326)

#get unique facility IDs, apply 1km buffer
prisons_unique <- prisons %>% 
  st_buffer(1000)

### Wildfire Risk Raster (L:Drive) ----

wf_conus <- rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_conus.tif")

wf_ak <- rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_ak.tif") 

wf_hi <- rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_hi.tif")

#need to separate prisons file for conus, ak and hi

prisons_conus <- prisons_unique %>% filter(!(STATE %in% c("AK", "HI")))
prisons_ak <- prisons_unique %>% filter(STATE == "AK")
prisons_hi <- prisons_unique %>% filter(STATE == "HI")


# Convert rasters into the proper coordinate referance system, WGS1984
wf_conus_84 <- project(wf_conus, prisons_conus)
wf_ak_84 <- project(wf_ak, prisons_ak)
# Convert from "Hawaii_Albers_Equal_Area_Conic_USGS"
wf_hi_84 <- project(wf_hi, prisons_hi)

# Use mutate to calculate average wildfire risk value
## Custom raster_extract from https://github.com/michaeldorman/geobgu, which allows for stars, sf objects in calculation

# Blazing fast with dplyr
prisons_conus_wf <- prisons_conus %>% 
  mutate(wildfire_risk = terra::extract(wf_conus_84, prisons_conus, fun = "mean", na.rm = TRUE)) %>% 
  unnest(cols = wildfire_risk) %>% 
  select(!ID) %>% 
  rename("wildfire_risk" = "whp2020_cnt_conus")

prisons_ak_wf <- prisons_ak %>% 
  mutate(wildfire_risk = terra::extract(wf_ak_84, prisons_ak, fun = "mean", na.rm = TRUE)) %>% 
  unnest(cols = wildfire_risk) %>% 
  select(!ID) %>% 
  rename("wildfire_risk" = "whp2020_cnt_ak")

prisons_hi_wf <- prisons_hi %>% 
  mutate(wildfire_risk = terra::extract(wf_hi_84, prisons_hi, fun = "mean", na.rm = TRUE)) %>% 
  unnest(cols = wildfire_risk) %>% 
  select(!ID) %>% 
  rename("wildfire_risk" = "whp2020_cnt_hi")


# Resultant wildfire calculation dataset
prisons_all_wf <- bind_rows(prisons_conus_wf, prisons_ak_wf, prisons_hi_wf) %>% 
  select(!ID)

st_write(prisons_all_wf, "data/processed/wildfire_risk_prisons.shp")
  
# Visualizing the data
prisons <- prisons_all_wf %>% 
  st_centroid()

pal1 <- colorNumeric(palette = "Reds", domain = prisons$wildfire_risk)

leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons,
                   color = ~pal1(wildfire_risk),
                   radius = 5,
                   stroke = FALSE, fillOpacity = 1)






### SCRATCH Test Iteration ----
for (facility in 1:length(prison_unique_test)) {
  
  
  ## get bounding box
  bb <- st_bbox(prison_unique_test[facility,])
  
  ## extract bbox
  bb.ordered <-  paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")
  
  
  url_paste0 <- paste0(
    'https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_WildfireHazardPotential/ImageServer/',
    '/query?',
    '&geometry=',
    bb.ordered,
    '&geometryType=esriGeometryEnvelope',
    '&outFields=*',
    '&returnGeometry=true',
    '&returnZ=false',
    '&returnM=false',
    '&returnExtentOnly=false',
    '&f=geoJSON'
  )
  
}










# Fort Collins Test --------

# Fort Collins Test bbox
bb <- st_bbox(c(xmin = -105.89218,  ymin = 40.27989, xmax = -105.17284, ymax = 40.72316), crs = st_crs(4326))

url_correct <- paste0("https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_WildfireHazardPotential/ImageServer/query?outFields=*&f=geoJSON&where=1%3D1&geometry=",bb.ordered)

wildfire_risk <- terra::rast(url_correct)

# Produces one image of fort collins:
"https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_ExposureType/ImageServer/exportImage?bbox=-105.89218%2C+40.2789%2C+-105.173%2C+40.72&bboxSR=4326&size=&imageSR=4326&time=&format=jpgpng&pixelType=S32&noData=&noDataInterpretation=esriNoDataMatchAny&interpolation=+RSP_BilinearInterpolation&compression=&compressionQuality=&bandIds=&mosaicRule=&renderingRule=&f=image"

## Other Test URL calls using terra::rast & sf::read_sf & arcpullr -----

get_service_type("https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_WildfireHazardPotential/ImageServer/")
# Returns "image" ~ indicates functioning URL

get_image_layer("https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_WildfireHazardPotential/ImageServer/",
                          bb)
# Returns "File does not exist.. GDAL Error no. 1"

# Input manually the bbox of the first prison boundary
url <- paste0("https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_WildfireHazardPotential/ImageServer/query?where=&objectIds=&time=&geometry=-75.9182817292464%252C40.1909681967275%252C-75.915321679774%252C40.1926528560016&geometryType=esriGeometryEnvelope&inSR=4326&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=&returnGeometry=true&outSR=4326&returnIdsOnly=false&returnCountOnly=false&pixelSize=&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnDistinctValues=false&multidimensionalDefinition=&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&f=pjson")
# Returns "File does not exist.. GDAL Error no. 1" 


# Test Iteration
for (facility in 1:length(prison_unique_test)) {
  

  ## get bounding box
  bb <- st_bbox(prison_unique_test[facility,])
  
  ## extract bbox
  bb.ordered <-  paste(bb[1], bb[2], bb[3], bb[4], sep = "%2C")
  
  
  url_paste0 <- paste0(
    'https://apps.fs.usda.gov/fsgisx01/rest/services/RDW_Wildfire/RMRS_WRC_WildfireHazardPotential/ImageServer/',
    '/query?',
    '&geometry=',
    bb.ordered,
    '&geometryType=esriGeometryEnvelope',
    '&outFields=*',
    '&returnGeometry=true',
    '&returnZ=false',
    '&returnM=false',
    '&returnExtentOnly=false',
    '&f=geoJSON'
  )
  

  
}


get_layer_by_spatial(url_correct)
