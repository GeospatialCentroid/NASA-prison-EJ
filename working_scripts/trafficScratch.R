# scratch workflow for calculating traffic proximity indicator
# workflow: find all segments within 500m, divide each by distance and multiply by aadt

library(tidyverse)
library(sf)
library(tmap)

tmap_mode("view")



prisons <- read_sf("data/processed/study_prisons.shp")


load("data/processed/traffic_proximity/aadt_2018.RData")

# set attribute constant argument to supress sf warning w/ st_crop
st_agr(aadt_2018) = "constant"



# st_is_within_distance returns thousands of feature indexes....
prison_traffic <- prisons[1,] %>% 
  mutate(roads_buffer = st_is_within_distance(prisons[1,], aadt_2018, dist = 500))

## retrieve segments within 500m
segments <- aadt_2018[unlist(prison_traffic$roads_buffer),]


qtm(st_buffer(prison_traffic, 500))



# try buffer and st_intersect instead, this returns the correct features
buff <- st_buffer(prisons[3,], 500) %>% 
  mutate(segments_500m = st_intersects(., aadt_2018))


segments2 <- aadt_2018[unlist(buff$segments_500m),]

qtm(buff) +
  qtm(segments2)

# test st_intersection
roads_intersect <- st_intersection(st_buffer(prisons[1,], 500), aadt_2018)

# set up function structure
getTrafficProximity <- function(prisons, file, dist = 500, save = FALSE, path = NULL){
  
  load(file)
  
  
  # make an empty list
  traffic_scores <- vector("list", length = 4)
  
  for (i in 1:4) {
    
    # if no 'major' roads within 500m
    if (nrow(st_crop(aadt_2018, st_buffer(prisons[i, ], 500))) == 0) {
      
      traffic_scores[[i]] <- tibble(FACILITYID = prisons[i, ]$FACILITYID,
                                    trafficProx = 0)
      
    } else {
      # crop
      roads_crop <-
        st_crop(aadt_2018, st_buffer(prisons[i, ], 500)) %>%
        # group by unique aadt values, assuming these indicate distinct roads
        group_by(aadt) %>%
        # calculate closest distance from road to prison
        summarise(distance = min(st_distance(., prisons[i, ]))) %>%
        ungroup() %>%
        mutate(score = aadt / distance)
      
      # return traffic score tied to prison FACILITY ID
      traffic_scores[[i]] <-
        tibble(FACILITYID = prisons[i, ]$FACILITYID,
               trafficProx = sum(as.numeric(roads_crop$score))
        )
      
      
    }
    
    print(i)

  }
  
  
  # bind all prison traffic scores
  trafficProx <- bind_rows(traffic_scores)
  
  return(trafficProx)
  
}


