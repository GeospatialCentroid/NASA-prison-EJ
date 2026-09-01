source("setup.R")
library(purrr)
#' Load thinned CA sample points
#'
#' Loads the full sample of California residence points and filters it down
#' to the two spatially thinned subsets (1 km and 5 km minimum spacing),
#' returning each subset as a plain data frame, an sf object, or both.
#'
#' @param path Character. Path to the full sample dataset. Must have a
#'   `.csv` or `.gpkg` extension. Defaults to
#'   `"outputs/comparison/final_df_all_2026-07-21.gpkg"`.
#' @param return_type Character. One of `"csv"`, `"gpkg"`, or `"both"`.
#'   Controls which version(s) of the filtered data are returned:
#'   \itemize{
#'     \item `"csv"` — plain data frames with geometry dropped
#'     \item `"gpkg"` — sf objects with geometry retained
#'     \item `"both"` — all four (data frame + sf object for each thinning level)
#'   }
#'
#' @return A named list. Contents depend on `return_type`:
#'   \itemize{
#'     \item `"csv"`: `df_1km`, `df_5km`
#'     \item `"gpkg"`: `df_1km_sf`, `df_5km_sf`
#'     \item `"both"`: `df_1km`, `df_1km_sf`, `df_5km`, `df_5km_sf`
#'   }
#'
#' @details Requires two pre-existing thinned reference files on disk:
#'   `data/ca_sample/1km_ca_residences.gpkg` and
#'   `data/ca_sample/5km_ca_residences.gpkg`. These provide the `object_id`
#'   values used to subset `final_df` down to the thinned points — the
#'   thinning itself is not performed here, only the filtering/join


load_ca_samples <- function(path = "outputs/comparison/final_df_all_2026-07-21.gpkg",
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
    st_drop_geometry()
  
  df_5km_sf <- final_df %>% 
    filter(object_id%in%thin_5km$object_id) %>% 
    st_as_sf()
  df_5km <- df_5km_sf %>% 
    st_drop_geometry()
    
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

