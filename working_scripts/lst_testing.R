# compare different methods of calculating LST from MODIS

library(tidyverse)


# read in files

og_lst <- read_csv("data/processed/heat_risk/prison_lst.csv")

og_lst_daily <- read_csv("data/processed/heat_risk/prison_lst_daily_1_myd11.csv")


#calculate median values from daily and get total # images per prison
og_lst_daily_calc <- og_lst_daily %>% 
  group_by(FACILITYID) %>% 
  summarise(LST_summer = median(LST_mean),
            total_days = n())

og_lst %>% 
  filter(FACILITYID %in% og_lst_daily$FACILITYID) %>% 
  full_join(og_lst_daily_calc) %>% View()
