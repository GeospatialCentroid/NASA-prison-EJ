# map of study extent for NASA grant

library(sf)
library(tidyverse)
library(leaflet)
library(usmap)


# read in prison boundaries

prisons <- st_read("data/raw/prisons/Prison_Boundaries.shp") %>%
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



# interactive map

pal1 <- colorFactor(palette = c("blue", "orange"), domain = prisons$TYPE)

leaflet() %>% 
  addTiles() %>% 
  addCircleMarkers(data = prisons,
                   color = ~pal1(TYPE),
                   radius = ~sqrt(POPULATION)*0.1,
                   stroke = FALSE, fillOpacity = 1)


# static map



pt_trans <- usmap_transform(data = prisons, input_names = c("long", "lat"))


plot_usmap() +
  geom_point(data = pt_trans, aes(x = x, y = y, size = POPULATION, color = TYPE),
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
        
