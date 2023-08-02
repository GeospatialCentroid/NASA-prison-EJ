# compile prelim climate results and maps for AAG conf

library(tidyverse)
library(sf)
library(usmap)


# read in prison centroids
prisons <- read_csv("data/processed/prison_centroids.csv") %>% 
  #need to convert facilityid to numeric to join w/ processed datasets
  mutate(FACILITYID = as.numeric(FACILITYID))


#read in processed datasets
wildfire <- read_csv('data/processed/prisons_wildfire.csv')

flood <- read_csv("data/processed/floodRisk.csv")


heat <- read_csv("data/processed/prison_lst.csv")

#read in and combine canopy csvs
canopy_conus <- read_csv("data/processed/prison_canopy_CONUS.csv")
canopy_ak <- read_csv("data/processed/prison_canopy_AK.csv")
canopy_hi <- read_csv('data/processed/prison_canopy_HI.csv')

canopy <- bind_rows(canopy_conus, canopy_ak, canopy_hi)


#join all to prison points
prisons_processed <-
  purrr::reduce(list(prisons, wildfire, flood, heat, canopy),
                dplyr::left_join,
                by = 'FACILITYID') %>%
  #calculate percentiles for each indicator and climate component score (average of percentiles
  dplyr::mutate(across(
    c(
      wildfire_risk,
      flood_risk_percent,
      LST_Day_1km,
      percent_tree_cover
    ),
    .fns = list(pcntl = ~ cume_dist(.) * 100),
    .names = "{col}_{fn}"
  )) %>%
  #need to inverse canopy cover, since high values mean low risk
  mutate(percent_tree_cover_pcntl = 100-percent_tree_cover_pcntl) %>% 
  mutate(climate_pcntl = rowMeans(select(.,contains('pcntl')), na.rm = TRUE))


# tie to full prison dataset and save columns
prisons_full <- read_sf("data/processed/study_prisons.shp") %>% 
  st_drop_geometry() %>% 
  mutate(FACILITYID = as.numeric(FACILITYID)) %>% 
  select(-NAME) %>% 
  left_join(prisons_processed, by = 'FACILITYID')

write_csv(prisons_full, "data/processed/climate_risk_indicators.csv")


# map results

prisons_map <- usmap_transform(data = prisons_processed, input_names = c("long", "lat"))



# wildfire  
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = wildfire_risk, color = wildfire_risk),
             alpha = 0.6) +
  scale_colour_gradient(low = "#fca668", high = "#c40205")+
  scale_radius(range = c(0.1, 4))+
  labs(title = "Wildfire Hazard Potential")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        legend.position = "none",
        plot.title = element_text(family = "sans", face = "bold",size = 12)
  )

ggsave(filename = "figs/wildfire_risk_update.png")


# flood
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = flood_risk_percent, color = flood_risk_percent),
             alpha = 0.6) +
  scale_colour_gradient(low = "#c9e3ff", high = "#023b78")+
  scale_radius(range = c(0.1, 4))+
  labs(title = "Flood Hazard")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        legend.position = "none",
        plot.title = element_text(family = "sans", face = "bold",size = 12)
  )

ggsave(filename = "figs/floodrisk.png")



# heat risk
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = LST_Day_1km, color = LST_Day_1km),
             alpha = 0.6) +
  scale_colour_gradient(low = "#c9e3ff", high = "#c40205")+
  scale_radius(range = c(0.1, 4))+
  labs(title = "Heat Risk")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        legend.position = "none",
        plot.title = element_text(family = "sans", face = "bold",size = 12)
  )

ggsave(filename = "figs/heat_risk.png")


#canopy cover
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = percent_tree_cover, color = percent_tree_cover),
             alpha = 0.6) +
  scale_colour_gradient(low = "#b5f5c0", high = "#05871c")+
  scale_radius(range = c(0.1, 4))+
  labs(title = "Canopy Cover")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        legend.position = "none",
        plot.title = element_text(family = "sans", face = "bold",size = 12)
  )

ggsave(filename = "figs/canopy_cover.png")



# top 10 at risk prisons
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = arrange(prisons_map, desc(climate_pcntl))[1:10,], aes(x = x, y = y),
             alpha = 0.6, size = 3, color = "red") +
  #scale_colour_gradient(low = "#b5f5c0", high = "#05871c")+
  #scale_radius(range = c(0.1, 4))+
  labs(title = "Top 10 Climate Risk Prisons in the U.S.")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        plot.title = element_text(family = "sans", face = "bold",size = 12)
       )#+
  #guides(color= guide_legend(title = "Prison Percentile"), size=guide_legend(title = "Prison Percentile"))

ggsave(filename = "figs/climate_top10.png")
