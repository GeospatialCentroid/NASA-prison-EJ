# code base to run individual environmental indicator functions


# set up environment -----------------
source("setup.R")

# read in processed prison polygons
prisons <- read_sf("data/processed/prisons/study_prisons.shp")


# run individual indicator functions -------------------


# flood risk (takes 1-2 days to run)
flood_risk <- calc_flood_risk(sf_obj = prisons)


# wildfire risk
wildfire_risk <- calc_wildfire_risk(
  sf_obj = prisons,
  file = "data/raw/wildfire_risk/whp2020_GeoTIF/"
)


# ozone
ozone <- calc_ozone(
  sf_obj = prisons, 
  folder = "data/raw/air_quality/o3_daily/",
  dist = 1000, years = c(2014, 2016)
)


# pm2.5 (may change dataset, check for more recent years)
pm25 <-
  calc_pm25(
    sf_obj = prisons,
    folder = "data/raw/air_quality/pm2.5_sedac/",
    dist = 1000,
    years = c(2017, 2019),
    save = FALSE
  )


# pesticides
pesticides <- calc_pesticides(prisons, 
                             folder = "data/raw/pesticides/ferman-v1-pest-chemgrids-v1-01-geotiff",
                             dist = 1000, 
                             save = TRUE)


# traffic proximity (takes 1.5 days to run on Desktop comp)
traffic_prox <- calc_traffic_proximity(
  sf_obj = prisons,
  file = "data/processed/traffic_proximity/aadt_2018.RData"
)


# calculate Risk Management Plan (RMP) facility proximity
rmp_prox <- calc_rmp_proximity(
  sf_obj = prisons,
  file = "data/raw/EPA_RMP/EPA_Emergency_Response_(ER)_Risk_Management_Plan_(RMP)_Facilities.csv"
)


# calculate NPL facility proximity
npl_prox <- calc_npl_proximity(
  sf_obj = prisons,
  file = "data/processed/npl_addresses_geocoded_arc_sf.csv"
)


# calculate Haz waste facility proximity
haz_prox <- calc_haz_waste_proximity(
  sf_obj = prisons,
  file = "data/processed/hazardous_waste/TSD_LQGs.csv"
)


# component score calculation (pulling in files saved above) ---------------


## climate scores -------------

flood_risk <- read_csv("outputs/flood_risk_2023-03-10.csv") %>%
  select(FACILITYID, flood_risk = flood_risk_percent)

wildfire_risk <- read_csv("outputs/wildfire_risk_2023-08-29.csv") %>%
  select(-geometry)

heat_exp <- read_csv("data/processed/heat_exposure/lst_average.csv")

canopy_cover <- read_csv("data/processed/canopy_cover/prison_canopy_AK.csv") %>%
  bind_rows(read_csv("data/processed/canopy_cover/prison_canopy_HI.csv")) %>%
  bind_rows(read_csv("data/processed/canopy_cover/prison_canopy_CONUS.csv"))


climate_scores <- list(flood_risk, wildfire_risk, heat_exp, canopy_cover) %>%
  # convert FACILITYID to character for all to make sure they join
  purrr::map(~ .x %>% mutate(FACILITYID = as.character(FACILITYID))) %>% 
  purrr::reduce(left_join, by = "FACILITYID") %>%
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


## env exposures scores ----------------

ozone <- read_csv("outputs/ozone_2023-08-15.csv")

pm25 <- read_csv("outputs/pm25_2023-08-10.csv")

pesticides <- read_csv("outputs/pesticides_2023-08-14.csv")

traffic <- read_csv("outputs/traffic_prox_2023-05-13.csv")

exposure_scores <- list(ozone, pm25, pesticides, traffic) %>%
  # convert FACILITYID to character for all to make sure they join
  purrr::map(~ .x %>% mutate(FACILITYID = as.character(FACILITYID))) %>% 
  purrr::reduce(left_join, by = "FACILITYID") %>%
  # calculate percentile columns for each raw indicator
  dplyr::mutate(across(
    where(is.numeric),
    .fns = list(pcntl = ~ cume_dist(.) * 100),
    .names = "{col}_{fn}"
  )) %>%
  rowwise() %>%
  # calculate climate component score (geometric mean of indicator percentiles)
  mutate(exposure_score = gm_mean(c_across(contains("pcntl"))))



## env effects scores -------------------


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



# final data frame ----------------------------

final_df <- list(climate_scores, exposure_scores, effects_scores) %>%
  purrr::reduce(left_join, by = "FACILITYID") %>%
  # remove rowwise
  ungroup() %>%
  mutate(
    final_risk_score = rowMeans(select(., contains("score"))),
    final_risk_score_pcntl = cume_dist(final_risk_score) * 100
  )%>% 
  # join with original prison facility metadata
  mutate(FACILITYID = as.character(FACILITYID)) %>% 
  left_join(prisons, by = "FACILITYID")

# save as shapefile and csv
final_df %>% st_as_sf() %>% st_write(paste0("outputs/final_df_", Sys.Date(), ".gpkg", driver="GPKG"))

final_df %>% 
  select(-geometry) %>% 
  write_csv(paste0("outputs/final_df_", Sys.Date(), ".csv"))