# explore avg prison area/census tract or block group to see if viable resolution

library(tidyverse)
library(tigris)
library(sf)
library(tmap)

tmap_mode("view")


# Read in prison shapefile
prisons <- read_sf("data/processed/study_prisons.shp")


# Census Tracts --------------------

# Read in census tracts
tracts <- tigris::tracts(cb = TRUE)

# add area column
tracts <- tracts %>% 
  mutate(tract_area = st_area(.))



# join prisons to their census tract
prison_tracts <- prisons %>% 
  st_transform(crs = st_crs(tracts)) %>% 
  # add column for prison area
  mutate(prisons_area = st_area(.)) %>% 
  st_join(tracts)


#now calculate % prison area covers census tract
prison_tract_coverage <- prison_tracts %>% 
  group_by(FACILITYID) %>% 
  summarise(coverage = (sum(prisons_area)/sum(tract_area))*100) # use sum b/c looks like some prisons might overlap multiple tracts

#explore coverage
mean(prison_tract_coverage$coverage)
#1.265265%

hist(prison_tract_coverage$coverage)

boxplot(prison_tract_coverage$coverage)

#Okay, prisons cover very small portion of census tract


# convert sq meters to sq km
prison_tracts <- prison_tracts %>% 
  mutate(prison_area_km = as.numeric(prisons_area)/1000000)


mean(prison_tracts$prison_area_km)
# on average prisons are much smaller than 1km resolution, so for LST going to
# just extract points.



## Block groups -------------------------------

# Read in block groups
blocks <- tigris::block_groups(cb = TRUE)

# add area column
blocks <- blocks %>% 
  mutate(block_area = st_area(.))



# join prisons to their block groups
prison_blocks <- prisons %>% 
  st_transform(crs = st_crs(blocks)) %>% 
  # add column for prison area
  mutate(prisons_area = st_area(.)) %>% 
  st_join(blocks)


#now calculate % prison area covers census tract
prison_block_coverage <- prison_blocks %>% 
  group_by(FACILITYID) %>% 
  summarise(coverage = (sum(prisons_area)/sum(block_area))*100) # use sum incase some prisons overlap multiple blocks?

#explore coverage
mean(prison_block_coverage$coverage)
# 2.38

hist(prison_block_coverage$coverage, breaks = 40)

# vast majority only cover 2% or less of the census block




