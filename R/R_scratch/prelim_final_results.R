library(tidyverse)
library(sf)

# depending on R version, need older version of usmap
require(devtools)
install_version("usmap", version = "0.6.1", repos = "http://cran.us.r-project.org")

library(usmap)

# read in final data frame

df <- read_csv("data/processed/final_df_2023-07-27.csv")


# data exploration ------------------------------------------------

# read in prison shapefile with full info
prisons <- read_sf("data/processed/study_prisons.shp")


# convert final score to percentile and tie to full prison info
df_stats <- df %>% 
  mutate(FACILITYID = as.character(FACILITYID)) %>% 
  left_join(prisons, by = "FACILITYID")

# find top 100 and look at prison stats
top100 <- arrange(df_stats, -final_risk_score_pcntl)[1:100,] 
  


top100 %>% group_by(STATE) %>% count()
# 30% in CA, 

#But compare this to total % of CA prisons in data set
df_stats %>% group_by(STATE) %>% count()
# 5% in CA (106)





# map results --------------------------------------------------



# read in processed prison centroids
prison_centroids <- read_sf("data/processed/prison_centroids.csv") %>% 
  #need to convert facilityid to numeric to join w/ processed datasets
  mutate(FACILITYID = as.numeric(FACILITYID),
         long = as.numeric(long),
         lat = as.numeric(lat))


# read in final df
df_map <- df %>% 
  #join to centroid points
  left_join(prison_centroids, by = "FACILITYID")



prisons_map <- usmap::usmap_transform(data = df_map, input_names = c("long", "lat"))


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
  geom_point(data = prisons_map, aes(x = x, y = y, size = final_risk_score_pcntl, color = final_risk_score_pcntl),
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

ggsave(filename = "figs/vulnerability_score_prelim_pcnt.png")


# top 100 at risk prisons
plot_usmap(color = "#b3b3b3", size = 0.35) +
  geom_point(data = arrange(prisons_map, desc(final_risk_score_pcntl))[1:50,], aes(x = x, y = y),
             alpha = 0.6, size = 3, color = "red") +
  #scale_colour_gradient(low = "#b5f5c0", high = "#05871c")+
  #scale_radius(range = c(0.1, 4))+
  labs(title = "Top 10 Climate Risk Prisons in the U.S.")+
  theme(plot.margin = margin(0,0,0,0,"cm"),
        plot.title = element_text(family = "sans", face = "bold",size = 12)
  )
