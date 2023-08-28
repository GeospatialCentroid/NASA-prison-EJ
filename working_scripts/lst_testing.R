# compare different methods of calculating LST from MODIS

library(tidyverse)


# read in files

og_lst <- read_csv("data/processed/heat_risk/prison_lst.csv")

og_lst_daily <- read_csv("data/processed/heat_risk/prison_lst_daily_1_myd11.csv")

lst_daily_qc2 <- read_csv("data/raw/heat_exposure/prison_lst_daily_1_myd11_QCV2.csv")

#calculate median values from daily and get total # images per prison
og_lst_daily_calc <- og_lst_daily %>% 
  group_by(FACILITYID) %>% 
  summarise(LST_summer = median(LST_mean),
            total_days = n())

og_lst %>% 
  filter(FACILITYID %in% og_lst_daily$FACILITYID) %>% 
  full_join(og_lst_daily_calc) %>% View()

# compare # images per site among QC methods
lst_daily_qc2_calc <-  lst_daily_qc2 %>% 
  group_by(FACILITYID) %>% 
  summarise(LST_summer_qc2 = median(LST_mean),
            total_days_qc2 = n()) %>% 
  full_join(og_lst_daily_calc) %>% filter(total_days_qc2 != total_days) %>% 
  View()

# only 100 sites that had different # images, all had more. So let's stick with
# the original QC method