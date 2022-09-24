# Create preliminary map for Google conf

library(sf)
library(terra)
library(tidyverse)
library(leaflet)
library(tidygeocoder)


# read in prison locations
prisons <- st_read("data/Prison_Boundaries.shp") %>% 
  #filter out just state and federal
  filter(TYPE %in% c("STATE", "FEDERAL")) %>% 
  st_transform(4326) %>% 
  st_centroid() %>% 
  #filter just U.S. (not territories)
  filter(COUNTRY == "USA") %>% 
  # filter out prisons with 0 or NA population and that are designated as "closed"
  filter(POPULATION > 0) %>% filter(STATUS == "OPEN")


# WILDIFRE ------------------------------------------------
# read in wildfire risk (from L:/ drive)


wf_conus <- terra::rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_conus.tif")

wf_ak <- terra::rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_ak.tif") 

wf_hi <- terra::rast("L:/Projects_active/EnviroScreen/data/wildfire/Data/whp2020_GeoTIF/whp2020_cnt_hi.tif") 



# extract conus values from prisons
wf_conus <- project(wf_conus, vect(prisons))


prisons$wildfire <- terra::extract(wf_conus, vect(prisons))[,2]



#quick map
pal1 <- colorNumeric(palette = "Reds", domain = prisons$wildfire)

leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons,
                   color = ~pal1(wildfire),
                   radius = 5,
                   stroke = FALSE, fillOpacity = 1)


# HEAT DAYS -----------------------------------------------------------

# heat index (average number of days from May - Sept 2016 - 2021 in which daily
# high temp exceeded the 90th percentile of historical daily temperatures, at the county level)


heat_days <- read_csv("data/heat_days/data_181732.csv") %>% 
  group_by(State, County, CountyFIPS) %>% 
  dplyr::summarise(heat_index = mean(Value))


#get spatial county data to tie to points
counties <- tigris::counties()

county_heat_index <- counties %>% 
  mutate(CountyFIPS = paste0(STATEFP, COUNTYFP)) %>% 
  left_join(heat_days, by = "CountyFIPS") %>% 
  st_transform(st_crs(prisons))


prisons_hi <- prisons %>% 
  st_join(county_heat_index["heat_index"])



pal1 <- colorNumeric(palette = "Reds", domain = prisons_hi$heat_index)

#quick plot
leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons_hi,
                   color = ~pal1(heat_index),
                   radius = 4.5,
                   stroke = FALSE, fillOpacity = 0.8)


# NPL SITES ---------------------------------------------------------

npl <- readr::read_csv("data/npl_sites.csv", skip = 13) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_sub(zip_code, 2, 6))

npl_geo <- npl %>% 
  unite(full_address, c("street_address", "city", "state"), sep = ", ") %>%
  unite(full_address, c("full_address", "zip_code"), sep = " ") %>% 
  filter(!(epa_id  %in% c("AZD094524097", "MOD981507585"))) %>% # remove rows with weird characters
  tidygeocoder::geocode(full_address, method = 'osm', lat = latitude , long = longitude) 


#save file since that took a long time
write_csv(npl_geo, file = "data/npl_coords.csv")

#remove NAs and set CRS
npl_geo <- npl_geo %>% 
  filter(!is.na(latitude) & !is.na(longitude)) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)


#find nearest npl feature for each prison
prisons$nearest_npl <- st_nearest_feature(prisons, npl_geo)

#calculate distance to nearest npl
prisons$npl_dist <- st_distance(prisons, npl_geo[prisons$nearest_npl,], by_element = TRUE)


#subset prisons within 1km of npl, and which npls those are

prisons_npl1km <- prisons %>% 
  mutate(npl_dist_m = as.numeric(npl_dist)) %>% 
  filter(npl_dist_m < 1000)


npl_prison1km <- npl_geo[prisons_npl1km$nearest_npl,]


#map

leaflet() %>% 
  addProviderTiles('Esri.WorldImagery') %>% 
  addCircleMarkers(data = prisons_npl1km,
                   popup = paste(
                     "NAME:",
                     prisons_npl1km$NAME,
                     "<br>",
                     "Population:",
                     prisons_npl1km$POPULATION
                   )) %>% 
  addCircleMarkers(data = npl_prison1km, color = "red",
                   popup = paste(
                     "NPL Status:",
                     npl_prison1km$npl_status,
                     "<br>",
                     "Site Type:",
                     npl_prison1km$site_type,
                     "<br>",
                     "Human exposure under control:",
                     npl_prison1km$human_exposure_under_control
                   ))


# PM2.5 -----------------------------------------------------------


aq <- vroom("L:/Projects_active/EnviroScreen/data/epa_cmaq/2017_pm25_daily_average.txt.gz")

