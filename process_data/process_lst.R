# process the raw daily LST files from calc_myd11_lst_day.py script

library(tidyverse)

# read in file from data/raw folder
lst_daily <- read_csv("data/raw/heat_exposure/prison_lst_daily_all_2023-08-30.csv")


# calculate summer average for each year
lst_change <- lst_daily %>% 
  select(-.geo) %>% 
  separate(date, into = c("year", "month", "day"), sep = "_") %>% 
  group_by(FACILITYID, year) %>% 
  summarise(mean = mean(LST_mean)) %>% 
  # arrange by year to use 'lag()' to calculate rate of change
  arrange(FACILITYID, year) %>% 
  mutate(rate = 100 * (mean - lag(mean))/lag(mean)) %>% 
  # get overall change in temp over 10 years
  group_by(FACILITYID) %>% 
  summarise(ave_rate = mean(rate, na.rm = TRUE))

# calculate total average across all days/years
lst_summary <- lst_daily %>% 
  group_by(FACILITYID) %>% 
  summarise(lst_avg = median(LST_mean, na.rm = TRUE))

# keep just total average for final dataset
write_csv(lst_summary, paste0("data/processed/heat_exposure/lst_average_", 
                              Sys.Date(), ".csv"))
