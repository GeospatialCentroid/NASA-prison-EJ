# test pulling FEMA flood hazard from ArcGIS Rest services

library(arcpullr)
library(sf)

#create bounding box, use CO to test
bbox = st_bbox(c(xmin = -105.89218,  ymin = 40.27989, xmax = -105.17284, ymax = 40.72316), crs = st_crs(4326)) %>% 
  st_as_sfc() %>% 
  st_as_sf()


flood <- get_spatial_layer(url = "https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHLWMS/MapServer/28",
                       sf_object = bbox)
