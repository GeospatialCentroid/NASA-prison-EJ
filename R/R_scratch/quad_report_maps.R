# maps for Quad Report


source("R/R_scratch/point_data_factors.R")


#add column that assigns total weights
# give 1 to 1km, 0.5 to 5km, and 0.25 to 10km

dat <- power_prison_buffs %>% 
  mutate(score = sum(power_plants_1km*1 + power_plants_5km*0.5 + power_plants_10km*0.25)) %>% 
  select(FACILITYID, score)
#cume_dist doesn't work within mutate for some reason
dat$pcntl <- cume_dist(dat$score)*100


#map prisons by score
library(usmap)


p1 <- dat %>% 
  as.data.frame() %>% 
  mutate(long = unlist(map(.$geometry,1)),
         lat = unlist(map(.$geometry,2))) %>% 
  st_drop_geometry()

## use base code for prison location map

plant_map <- usmap_transform(data = p1, input_names = c("long", "lat"))


plot_usmap(color = "#b3b3b3") +
  geom_point(data = plant_map, aes(x = x, y = y, size = pcntl, color = pcntl),
             alpha = 0.75) +
  scale_colour_gradient(low = "#bfcbd6", high = "#01294a")+
  scale_radius(range = c(1, 6))+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"))+
  guides(color= guide_legend(title = "Prison Percentile"), size=guide_legend(title = "Prison Percentile"))

ggsave(filename = "www/power_plant_map.png")
