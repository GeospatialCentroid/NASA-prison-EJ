library(tidyverse)
library(sf)
library(usmap)


# read in processed prison centroids
prisons <- read_sf("data/processed/prison_centroids.csv") %>% 
  #need to convert facilityid to numeric to join w/ processed datasets
  mutate(FACILITYID = as.numeric(FACILITYID),
         long = as.numeric(long),
         lat = as.numeric(lat))


# read in final df
final_df <- read_csv("data/processed/final_df_2023-05-16.csv") %>% 
  #join to centroid points
  left_join(prisons, by = "FACILITYID")


# map results

prisons_map <- usmap_transform(data = final_df, input_names = c("long", "lat"))


# climate map
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = climateScore, color = climateScore),
             alpha = 0.6) +
  scale_colour_gradient(low = "#9dbd99", high = "#114a0a", limits = c(0,100))+
  scale_radius(range = c(0.1, 4), limits = c(0,100))+
  labs(title = "Climate Component Score")+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"),
        plot.title = element_text(size = 16, family = "sans"))+
  guides(color= guide_legend(title = "Prison\nPercentile"), size=guide_legend(title = "Prison\nPercentile"))

ggsave(filename = "figs/climate_component_prelim.png")



# exposures map

plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = exposureScore, color = exposureScore),
             alpha = 0.6) +
  scale_colour_gradient(low = "#baa9c7", high = "#410e69", limits = c(0,100))+
  scale_radius(range = c(0.1, 4), limits = c(0,100))+
  labs(title = "Environmental Exposures Component Score")+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"),
        plot.title = element_text(size = 16, family = "sans"))+
  guides(color= guide_legend(title = "Prison\nPercentile"), size=guide_legend(title = "Prison\nPercentile"))

ggsave(filename = "figs/exposure_component_prelim.png")


# effects map

plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = effectsScore, color = effectsScore),
             alpha = 0.5) +
  scale_colour_gradient(low = "#f7dbb7", high = "#fa8602", limits = c(0,100))+
  scale_radius(range = c(0.1, 4), limits = c(0,100))+
  labs(title = "Environmental Effects Component Score")+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"),
        plot.title = element_text(size = 16, family = "sans"))+
  guides(color= guide_legend(title = "Prison\nPercentile"), size=guide_legend(title = "Prison\nPercentile"))

ggsave(filename = "figs/effects_component_prelim.png")


# final risk score
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = prisons_map, aes(x = x, y = y, size = final_risk_score, color = final_risk_score),
             alpha = 0.5) +
  scale_colour_gradient(low = "lightgray", high = "black", limits = c(0,100))+
  scale_radius(range = c(0.1, 4), limits = c(0,100))+
  labs(title = "Environmental Vulnerability Score")+
  theme(plot.margin = margin(1,1,1,1,"cm"),
        legend.margin = margin(0,0,0,0,"cm"),
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(family = "sans", face = "bold",size = 12),
        legend.text = element_text(family = "sans",size = 9),
        legend.position = c(-0.06,0.10),
        legend.spacing = unit(0, "cm"),
        plot.title = element_text(size = 16, family = "sans"))+
  guides(color= guide_legend(title = "Prison\nPercentile"), size=guide_legend(title = "Prison\nPercentile"))

ggsave(filename = "figs/vulnerability_score_prelim.png")


# top 100 at risk prisons
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = arrange(prisons_map, desc(final_risk_score))[1:100,], aes(x = x, y = y),
             alpha = 0.6, size = 3, color = "red") +
  #scale_colour_gradient(low = "#b5f5c0", high = "#05871c")+
  #scale_radius(range = c(0.1, 4))+
  labs(title = "Top 10 Climate Risk Prisons in the U.S.")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        plot.title = element_text(family = "sans", face = "bold",size = 12)
  )
