#' Calculate pesticide use per prison facility using USGS EPest county estimates
#'
#' Joins prison facilities to USGS EPest county-level pesticide data via a spatial
#' join to US county boundaries (TIGER). Returns total pesticide use (kg/yr) for
#' the county containing each facility, summed across all compounds, averaged
#' across EPest-low and EPest-high estimates.
#'
#' @param sf_obj     An sf object of prison polygons, must have a FACILITYID column
#' @param path      File path to the EPest tab-delimited text file
#' @param year       Integer year matching the EPest file (used only for labeling output)
#' @param compounds  Optional character vector of compound names to filter to.
#'                   If NULL (default), all compounds are summed.
#' @param save       Whether to save (TRUE) the result as a .csv
#' @param outout_dir   If save = TRUE, folder path for output csv
#'
#' @return A data frame with one row per facility:
#'   FACILITYID, county_fips, pesticide_mean_kg

calc_pesticides_EPest <- function(sf_obj,
                            path,
                            year = 2019,
                            compounds = NULL,
                            save = TRUE,
                            output_dir = "outputs/") {
  
  
  # --- 1. Load and prep EPest data -------------------------------------------
  
  epest <- read_tsv(path, col_types = cols(
    COMPOUND         = col_character(),
    YEAR             = col_integer(),
    STATE_FIPS_CODE  = col_character(),
    COUNTY_FIPS_CODE = col_character(),
    EPEST_LOW_KG     = col_double(),
    EPEST_HIGH_KG    = col_double()
  )) %>%
    mutate(
      county_fips = paste0(
        str_pad(STATE_FIPS_CODE, 2, pad = "0"),
        str_pad(COUNTY_FIPS_CODE, 3, pad = "0")
      ),
      EPEST_LOW_KG  = replace_na(EPEST_LOW_KG, 0),
      EPEST_HIGH_KG = replace_na(EPEST_HIGH_KG, 0)
    )
  
  if (!is.null(compounds)) {
    epest <- epest %>% filter(COMPOUND %in% toupper(compounds))
    message(sprintf("Filtered to %d compound(s): %s",
                    length(compounds), paste(compounds, collapse = ", ")))
  }
  
  epest_county <- epest %>%
    group_by(county_fips) %>%
    summarise(
      pesticide_low_kg  = sum(EPEST_LOW_KG,  na.rm = TRUE),
      pesticide_high_kg = sum(EPEST_HIGH_KG, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(pesticide_mean_kg = (pesticide_low_kg + pesticide_high_kg) / 2) %>%
    select(county_fips, pesticide_mean_kg)
  
  
  # --- 2. Load US county boundaries (TIGER) ----------------------------------
  
  message("Downloading TIGER county boundaries...")
  counties_sf <- tigris::counties(cb = TRUE, resolution = "20m", year = 2019) %>%
    select(county_fips = GEOID, geometry) %>%
    st_transform(crs = st_crs(sf_obj))
  
  
  # --- 3. Spatial join: prison centroids -> county ---------------------------
  
  prison_centroids <- sf_obj %>%
    st_centroid() %>%
    select(FACILITYID)
  
  prisons_county <- st_join(prison_centroids, counties_sf, join = st_within) %>%
    st_drop_geometry()
  
  n_unmatched <- sum(is.na(prisons_county$county_fips))
  if (n_unmatched > 0) {
    warning(sprintf(
      "%d facility centroid(s) did not fall within a county polygon. ",
      "These will have NA pesticide values. Check CRS and geometry validity.",
      n_unmatched
    ))
  }
  
  
  # --- 4. Join EPest values to facilities ------------------------------------
  
  result <- prisons_county %>%
    left_join(epest_county, by = "county_fips") %>%
    select(FACILITYID, pesticide_mean_kg)
  
  # message(sprintf(
  #   "Done. %d facilities matched across %d unique counties.",
  #   sum(!is.na(result$county_fips)),
  #   n_distinct(result$county_fips, na.rm = TRUE)
  # ))
  # 
  
  # --- 5. Optionally save ----------------------------------------------------
  
  if (save) {
    out_file <- paste0(output_dir, "pesticides_", Sys.Date(), ".csv")
    write_csv(result, out_file)
    message("Saved to: ", out_file)
  }
  
  return(result)
  
}