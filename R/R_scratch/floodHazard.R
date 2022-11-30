# Pull FEMA flood hazard from ArcGIS Rest services

library(sf)
library(tmap)


# make st_bbox

## test w/ foco area
bb <- st_bbox(c(xmin = -105.89218,  ymin = 40.27989, xmax = -105.17284, ymax = 40.72316), crs = st_crs(4326))


# extract bbox
bb.ordered <-  paste(bb[1],bb[2],bb[3],bb[4], sep = "%2C")


#choose layer
layer <- 28

#construct URL
url <- paste0('https://hazards.fema.gov/gis/nfhl/rest/services/public/',
              'NFHL/MapServer/',
              layer,
              '/query?',
              '&geometry=',
              bb.ordered,
              '&geometryType=esriGeometryEnvelope',
              '&outFields=*',
              '&returnGeometry=true',
              '&returnZ=false',
              '&returnM=false',
              '&returnExtentOnly=false',
              '&f=geoJSON')



floodHaz <- sf::read_sf(url)

# filter to zones that hve A or V in them - high-risk flood zones https://floodpartners.com/flood-zones/
floodRisk <- floodHaz %>%
  filter(stringr::str_detect(FLD_ZONE, 'A|V'))


#workflow, base off getFloodplain
# read in prison boundaries
# buffer
# each one, extract bbox, read in fema data
# intersect floodpRisk layer w/ prinson boundary + prison boundary buffer
# calculate area
# calculate percent covering prison boundary

# figure out fastest way to read in FEMA layer (all at once doesn't work, too big)


