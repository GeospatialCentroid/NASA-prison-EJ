# Process 2023 Traffic Data
## Downloaded from: https://geodata.bts.gov/datasets/483bd180fe814872b82a66dbf65e25f0/about 
# From metadata (https://www.fhwa.dot.gov/policyinformation/hpms/fieldmanual/hpms_field_manual_dec2016.pdf)
# f_system 1 - Interstate, 2 and 3 - Principal Arterial, 4 - Minor Arterial in urban areas only (NOT urban_code 99999, that is Rural)

source('setup.R')

# Data organized in geodatabase with a layer for each state. 
## Read in and clean each state, then bind at the end

traffic_all <- map(state.abb, function(x){
  
  data <- st_read("data/phase2/raw/Traffic/HPMS2023/HPMS2023.gdb", layer = paste0("HPMS_FULL_", x, "_2023"))
  
  #some state missing column naming or case is different (CT for example)
  if("Field6" %in% names(data)) {
    data <- data %>% 
      rename(F_SYSTEM = Field6, URBAN_ID = Field8)
  }
  
  data <- data %>% 
    # make all columns uppercase
    rename_with(toupper) %>% 
    filter(F_SYSTEM %in% 1:3 | F_SYSTEM == 4 & URBAN_ID != 99999)
  
  # need to remove invalid geometries and reproject to 5070 for distance calculations
  # drop Z/M coordinates
  data <- st_zm(data, drop = TRUE, what = "ZM")
  
  # filter out unsupported geometry types
  valid_types <- c("LINESTRING", "MULTILINESTRING", "POINT", "MULTIPOINT",
                   "POLYGON", "MULTIPOLYGON")
  data <- data[st_geometry_type(data) %in% valid_types, ]
  
  data <- st_transform(data, 5070)
  
  return(data)
               
})

# post processing needed before binding
traffic_cleaned <- map(traffic_all, ~mutate(., across(-all_of(attr(., "sf_column")), as.character)))
  
aadt_2023 <- bind_rows(traffic_cleaned)


# saving as geopackage and RData in case for file size
write_sf(aadt_2023, "data/phase2/processed/traffic/aadt_2023.gpkg")

save(aadt_2023, file = "data/phase2/processed/traffic/aadt_2023.RData")

