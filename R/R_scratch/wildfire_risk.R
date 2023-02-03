# Wildfire Risk across the United States ----
# File Created: Jan 30, 2023, Devin Hunt

## INITIALIZE ----

library(tidyverse)
library(arcpullr)


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


## arcpullr package version wasn't pulling image server

## IMPORT DATA ----
prisons <- read_sf('data/processed/study_prisons.shp') %>% 
  #transform to 4WGS84 to match floodplains
  st_transform(crs = 4326)

#get unique facility IDs, apply 1km buffer
prison_unique <- prisons %>% 
  distinct(FACILITYID, .keep_all = TRUE) %>% 
  mutate(buffer = st_buffer(., 1000))

# Slice for testing (speeding up iteration process)
prison_unique_test <- prisons %>% 
  slice_head(., n = 100)



## RUN CALCULATIONS ----

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
