# code base to run processing functions to calculate indicator scores

library(tidyverse)
library(sf)
library(terra)

# source all processing functions
lapply(
  list.files(
    path = "R/src/",
    pattern = ".R",
    full.names = TRUE
  ),
  source
)

# read in processed prison polygons
prisons <- read_sf("data/processed/prisons/study_prisons.shp")


# flood risk (takes 1-2 days to run, quite a few NAs too)
flood_risk <- calc_flood_risk(sf_obj = prisons)


# wildfire risk
wildfire_risk <- calc_wildfire_risk(
  sf_obj = prisons,
  file = "data/raw/wildfire/whp2020_GeoTIF/"
)


# ozone
ozone <- calc_ozone(
  sf_obj = prisons, folder = "data/raw/air_quality/o3-us-1-km-2000-2016-annual/",
  dist = 1000, years = c(2015, 2016)
)


# pm2.5 (may change dataset, check for more recent years)
pm25 <-
  calc_pm25(
    sf_object = prisons,
    folder = "data/raw/air_quality/pm2-5-us-1-km-2000-2016-annual/",
    dist = 1000,
    years = c(2015, 2016)
  )


# pesticides (ran this manually to save time re-creating all rasters)
pesticides <- calcPesticides(prisons, dist = 1000, save = TRUE)


# traffic proximity (takes 1.5 days to run on Desktop comp)
traffic_prox <- calc_traffic_proximity(
  sf_obj = prisons,
  file = "data/processed/traffic_proximity/aadt_2018.RData"
)


# calculate Risk Management Plan (RMP) facility proximity
rmpProx <- getRMP(prisons, save = TRUE, path = "data/processed/")


# calculate NPL facility proximity
npl_prox <- calc_npl_proximity(
  sf_obj = prisons,
  file = "data/processed/npl_addresses_geocoded_arc_sf.csv"
)


# calculate Haz waste facility proximity
hazProx <- getHazWaste(prisons, save = TRUE, path = "data/processed/")


## draft score calculation (pulling in files saved above) --------------------------------


# climate scores

floodRisk <- read_csv("data/processed/floodRisk.csv") %>%
  select(FACILITYID, flood_risk = flood_risk_percent)

wildfire_risk <- read_csv("data/processed/prisons_wildfire.csv") %>%
  select(-geometry)

heatRisk <- read_csv("data/processed/prison_lst.csv") %>%
  rename(lst = LST_Day_1km)

canopyCover <- read_csv("data/processed/prison_canopy_AK.csv") %>%
  bind_rows(read_csv("data/processed/prison_canopy_HI.csv")) %>%
  bind_rows(read_csv("data/processed/prison_canopy_CONUS.csv"))


climate_scores <- list(floodRisk, wildfireRisk, heatRisk, canopyCover) %>%
  purrr::reduce(left_join, by = "FACILITYID") %>%
  # make facility ID character
  mutate(FACILITYID = as.character(FACILITYID)) %>%
  # calculate percentile columns for each raw indicator
  mutate(across(
    where(is.numeric),
    .fns = list(pcntl = ~ cume_dist(.) * 100),
    .names = "{col}_{fn}"
  )) %>%
  # need to inverse canopy cover since high value is good
  mutate(percent_tree_cover_pcntl = cume_dist(desc(percent_tree_cover)) * 100) %>%
  rowwise() %>%
  # calculate climate component score (average all indicator percentile values per prison
  mutate(climate_score = gm_mean(c_across(contains("pcntl"))))


# env exposures scores

ozone <- read_csv("data/processed/ozone_2023-05-11.csv")

pm25 <- read_csv("data/processed/pm25_2023-05-11.csv")

pesticides <- read_csv("data/processed/pesticides_2023-05-11.csv")

traffic <- read_csv("data/processed/traffic_prox_2023-05-13.csv")

exposure_scores <- list(ozone, pm25, pesticides, traffic) %>%
  purrr::reduce(left_join, by = "FACILITYID") %>%
  # make facility ID character
  mutate(FACILITYID = as.character(FACILITYID)) %>%
  # calculate percentile columns for each raw indicator
  dplyr::mutate(across(
    where(is.numeric),
    .fns = list(pcntl = ~ cume_dist(.) * 100),
    .names = "{col}_{fn}"
  )) %>%
  rowwise() %>%
  # calculate climate component score (geometric mean of indicator percentiles)
  mutate(exposure_score = gm_mean(c_across(contains("pcntl"))))




# env effects scores


npl <- read_csv("data/processed/npl_prox_2023-05-16.csv")

rmp <- read_csv("data/processed/rmp_prox_2023-05-16.csv")

haz <- read_csv("data/processed/haz_prox_2023-05-16.csv")

effects_scores <- list(npl, rmp, haz) %>%
  purrr::reduce(left_join, by = "FACILITYID") %>%
  # make facility ID character
  mutate(FACILITYID = as.character(FACILITYID)) %>%
  # calculate percentile columns for each raw indicator
  dplyr::mutate(across(
    where(is.numeric),
    .fns = list(pcntl = ~ cume_dist(.) * 100),
    .names = "{col}_{fn}"
  )) %>%
  rowwise() %>%
  # calculate climate component score (average all indicator percentile values per prison
  mutate(effects_score = gm_mean(c_across(contains("pcntl"))))



# final score

final_df <- list(climate_scores, exposure_scores, effects_scores) %>%
  purrr::reduce(left_join, by = "FACILITYID") %>%
  # remove rowwise
  ungroup() %>%
  mutate(
    final_risk_score = rowMeans(select(., contains("score"))),
    final_risk_score_pcntl = cume_dist(final_risk_score) * 100
  )

# save!
write_csv(final_df, paste0("data/processed/final_df_", Sys.Date(), ".csv"))
