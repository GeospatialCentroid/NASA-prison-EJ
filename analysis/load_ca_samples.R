source("setup.R")

### this function pulls the 1 km and 5 km thinned points from the entire sample and returns the points as data frames

load_ca_samples <- function(path = "outputs/comparison/final_df_all_2026-06-29.gpkg",
                            return_type = "csv"){
  
  #check condition on return type
  if (!return_type %in% c("csv", "gpkg", "both")) {
  stop("`return_type` must be 'csv', 'gpkg', or 'both'.")
 }
  #check that type and path are compatible 
  ext <- tools::file_ext(path)
  
  #load in path
  if (ext == "csv"){
    final_df <- read_csv(path, show_col_types = FALSE)
  } else if (ext == "gpkg"){
    final_df <- read_sf(path)
  } else {
    stop("Path does not match csv or gpkg.")
  }
  
  #load in thinned samples
  thin_1km <- read_sf("data/ca_sample/1km_ca_residences.gpkg")
  thin_5km <- read_sf("data/ca_sample/5km_ca_residences.gpkg")
  
  #filter final_df to just thinned points
  df_1km_sf <- final_df %>% 
    filter(object_id%in%thin_1km$object_id) %>% 
    st_as_sf()
  df_1km <- df_1km_sf %>% 
    select(-geom)
  
  df_5km_sf <- final_df %>% 
    filter(object_id%in%thin_5km$object_id) %>% 
    st_as_sf()
  df_5km <- df_5km_sf %>% 
    select(-geom)
    
  if(return_type == "csv"){
    return(list(df_1km = df_1km,
                df_5km = df_5km))
  } else if (return_type == "gpkg"){
    return(list(df_1km_sf = df_1km_sf,
                df_5km_sf = df_5km_sf))
  } else {
    return(list(df_1km = df_1km,
                df_1km_sf = df_1km_sf,
                df_5km = df_5km,
                df_5km_sf = df_5km_sf))
  }
}

