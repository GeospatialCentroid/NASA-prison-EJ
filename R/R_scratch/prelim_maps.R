# Create preliminary map for Google conf

library(sf)
library(terra)
library(tidyverse)
library(leaflet)
library(tidygeocoder)
library(usmap)
library(vroom)


# read in prison locations
prisons <- st_read("data/raw/Prison_Boundaries.shp") %>% 
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



# extract values from prisons
wf_conus <- project(wf_conus, vect(prisons))

wf_ak <- project(wf_ak, vect(prisons))

wf_hi <- project(wf_hi, vect(prisons))

#need to separate prisons file for conus, ak and hi

prisons_conus <- prisons %>% filter(!(STATE %in% c("AK", "HI")))
prisons_ak <- prisons %>% filter(STATE == "AK")
prisons_hi <- prisons %>% filter(STATE == "HI")


prisons_conus$wildfire <- terra::extract(wf_conus, vect(prisons_conus))[,2]
prisons_ak$wildfire <- terra::extract(wf_ak, vect(prisons_ak))[,2]
prisons_hi$wildfire <- terra::extract(wf_hi, vect(prisons_hi))[,2]

prisons <- bind_rows(prisons_conus, prisons_ak, prisons_hi)



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


heat_days <- read_csv("data/raw/heat_days/data_181732.csv") %>% 
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


#map all prisons dist to closest npl

prisons <- prisons %>% 
  mutate(npl_dist_m = as.numeric(npl_dist))

pal1 <- colorQuantile(palette = "Reds", domain = prisons$npl_dist_m, reverse = TRUE)

#quick plot
leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons,
                   color = ~pal1(npl_dist_m),
                   radius = 4.5,
                   stroke = FALSE, fillOpacity = 0.8)



# PM2.5 -----------------------------------------------------------


aq <- vroom("L:/Projects_active/EnviroScreen/data/epa_cmaq/2017_pm25_daily_average.txt.gz")


# clean down to census tract level (values rep by census tract centroids)
aq_clean <- aq %>% 
  #convert columns to numeric
  mutate(Latitude = as.numeric(Latitude),
         pm_25_daily_av = as.numeric(`pm25_daily_average(ug/m3)`)) %>% 
  group_by(FIPS) %>% 
  summarise(pm25_mean = mean(pm_25_daily_av))


#make spatial?
aq_sp <-aq %>% 
  #convert columns to numeric
  mutate(Latitude = as.numeric(Latitude),
         pm_25_daily_av = as.numeric(`pm25_daily_average(ug/m3)`)) %>% 
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)


#find nearest pm25 location for each prison
prisons$nearest_pm25 <- st_nearest_feature(prisons, aq_sp)
#this took over a day, so cancelled


#add cencus tract geometry and st_join prison points
censusTract <- tigris::tracts(cb = TRUE)


tract_pm25 <- censusTract %>% 
  left_join(aq_clean, by = c("GEOID" = "FIPS")) %>% 
  st_transform(st_crs(prisons))


prisons_pm25 <- prisons %>% 
  st_join(tract_pm25["pm25_mean"])



#quick map
pal1 <- colorQuantile(palette = "Reds", domain = prisons_pm25$pm25_mean)

#quick plot
leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons_pm25,
                   color = ~pal1(pm25_mean),
                   radius = 4.5,
                   stroke = FALSE, fillOpacity = 0.8)




# MAPS FOR GOOGLE PRES

#combine to single data frame

#convert both back to dataframe with lat/long columns
p1 <- prisons %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2))) %>% 
  st_drop_geometry() %>% 
  #add percentiles
  mutate(wildfire_pct = cume_dist(wildfire)*100,
         npl_pct = cume_dist(npl_dist_m)*100)

p2 <- prisons_pm25 %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2))) %>% 
  st_drop_geometry() %>% 
  mutate(pm25_pct = cume_dist(pm25_mean)*100)

prisons_prelim <- left_join(p1, p2, by = "FACILITYID") #this is messy, just skip this for now


## use base code for prison location map

#wildfire map ---------------------------------------

wf_map <- usmap_transform(data = p1, input_names = c("long", "lat"))


plot_usmap(color = "#b3b3b3") +
  geom_point(data = wf_map, aes(x = x, y = y, size = wildfire_pct, color = wildfire_pct),
             alpha = 0.6) +
  scale_colour_gradient(low = "#ebc7c8", high = "#c40205")+
  scale_radius(range = c(0.1, 4))+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"))+
  guides(color= guide_legend(title = "Prison Percentile"), size=guide_legend(title = "Prison Percentile"))

ggsave(filename = "www/wildfire_map.png")

# NPL map ----------------------------------------------------
npl_map <- usmap_transform(data = p1, input_names = c("long", "lat"))


plot_usmap(color = "#b3b3b3") +
  geom_point(data = npl_map, aes(x = x, y = y, size = -log(npl_dist_m), color = -log(npl_dist_m)),
             alpha = 0.75) +
  scale_colour_gradient(low = "#bfcbd6", high = "#01294a")+
  scale_radius(range = c(1, 6))+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        legend.position = "none")

ggsave(filename = "www/npl_map.png")



#pm2.5 map
pm25_map <- usmap_transform(data = p2, input_names = c("long", "lat"))


plot_usmap(color = "#b3b3b3") +
  geom_point(data = pm25_map, aes(x = x, y = y, size = pm25_pct, color = pm25_pct),
             alpha = 0.7) +
  scale_colour_gradient(low = "#b8ccb8", high = "#076904")+
  scale_radius(range = c(0.2, 6))+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"))+
  guides(color= guide_legend(title = "Prison Percentile"), size=guide_legend(title = "Prison Percentile"))

ggsave(filename = "www/pm25_map.png")



# PRISON MAP

plot_usmap(color = "#b3b3b3") +
  geom_point(data = wf_map, aes(x = x, y = y, size = POPULATION, color = TYPE),
             alpha = 0.6) +
  scale_color_manual(values = c("FEDERAL" = "#ed7b09", "STATE" = "#34aec7"))+
  scale_radius(breaks = c(1000, 3000, 6000),
               labels = c("< 1,000", "3,000", "> 6,000"))+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(0.02,0.15),
        legend.spacing = unit(0, "cm")) +
  guides(color = guide_legend(override.aes = list(size = 5)))


ggsave(filename = "www/prison_map.png")
