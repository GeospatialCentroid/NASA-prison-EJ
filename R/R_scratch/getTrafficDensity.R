# working script to calculate traffic density indicator

library(tidyverse)
library(vroom)
library(sf)


# read in raw data
traffic <- vroom("data/raw/traffic_density/TMAS_2020.csv")
