#' Calculate ozone risk using EPA FAQSD Downscaler data
#'
#' Calculates the 4th-highest daily 8-hour maximum ozone concentration
#' averaged across specified years for each prison polygon, using the EPA
#' Fused Air Quality Surface Using Downscaling (FAQSD) product.
#'
#' FAQSD fuses AQS monitor observations with 12 km CMAQ model output via a
#' Bayesian space-time downscaler. Output is one value per 2010 Census tract
#' centroid per day. Spatial matching is done by computing each prison polygon
#' centroid and finding the nearest tract centroid.
#'
#' Expected file path structure:
#'   data/phase2/raw/ozone/{year}_ozone_daily_8hour_maximum_2010_census.txt
#'
#' Data source:
#'   EPA HESC RSIG FAQSD — https://www.epa.gov/hesc/rsig-related-downloadable-data-files
#'   Columns: DATE, FIPS, LONGITUDE, LATITUDE,
#'            OZONE_DAILY_8HOUR_MAXIMUM.PPB., OZONE_DAILY_8HOUR_MAXIMUM_STDERR.PPB.
#'
#' @param sf_obj   An sf object of prison polygons to be assessed.
#' @param years    Integer vector of years to average across.
#'                 Default is c(2021, 2022) — the recommended years available
#'                 in the census tract format, skipping 2020 due to anomalous
#'                 COVID-related emission reductions.
#' @param data_dir Path to folder containing the FAQSD .txt files.
#'                 Default is "data/phase2/raw/ozone".
#' @param save     Logical. Whether to save results as CSV. Default TRUE.
#' @param out_path Directory path for the saved CSV. Default "outputs/".
#'
#' @return A tibble with columns FACILITYID, mean_ozone (ppb), matched_CTFIPS,
#'         and dist_to_tract_m — one row per facility.
#'
#' @examples
#' \dontrun{
#' prisons <- sf::st_read("study_prisons.shp")
#'
#' result <- calc_ozone_faqsd(prisons)
#'
#' result <- calc_ozone_faqsd(prisons, years = c(2021, 2022),
#'                            data_dir = "data/phase2/raw/ozone")
#' }

calc_ozone_faqsd <- function(
    sf_obj,
    years    = c(2021, 2022),
    data_dir = "data/phase2/raw/ozone",
    save     = TRUE,
    out_path = "outputs/"
) {
  
  # -- 0. Dependencies --------------------------------------------------------
  required_pkgs <- c("dplyr", "sf", "vroom", "purrr", "lubridate", "readr")
  invisible(lapply(required_pkgs, function(p) {
    if (!requireNamespace(p, quietly = TRUE))
      stop(sprintf("Package '%s' is required. Install with install.packages('%s')", p, p))
    library(p, character.only = TRUE)
  }))
  
  # -- 1. Validate inputs -----------------------------------------------------
  if (2020 %in% years)
    warning(
      "Year 2020 included. COVID-related emission reductions produced ",
      "anomalously low ozone precursor levels that year. ",
      "Consider excluding it from multi-year averages."
    )
  
  # -- 2. Load FAQSD data for each year ---------------------------------------
  load_year <- function(year) {
    
    filepath <- file.path(
      data_dir,
      sprintf("%d_ozone_daily_8hour_maximum_2010_census.txt", year)
    )
    
    if (!file.exists(filepath))
      stop(sprintf("File not found for year %d:\n  %s", year, filepath))
    
    message(sprintf("  [%d] Reading %s", year, basename(filepath)))
    
    df <- vroom::vroom(
      filepath,
      delim          = " ",
      show_col_types = FALSE,
      na             = c("", "NA", "-999", "-9999")
    )
    
    # Normalise column names to uppercase
    names(df) <- toupper(names(df))
    
    # Standardise column names across file vintages:
    #   Newer files: OZONE_DAILY_8HOUR_MAXIMUM.PPB., FIPS
    #   Older files: DS_O3_PRED, CTFIPS
    df <- df %>%
      rename_with(~ "DS_O3_PRED",
                  any_of(c("DS_O3_PRED",
                           "OZONE_DAILY_8HOUR_MAXIMUM.PPB.",
                           "OZONE_DAILY_8HOUR_MAXIMUM_PPB_"))) %>%
      rename_with(~ "DS_O3_STDD",
                  any_of(c("DS_O3_STDD",
                           "OZONE_DAILY_8HOUR_MAXIMUM_STDERR.PPB.",
                           "OZONE_DAILY_8HOUR_MAXIMUM_STDERR_PPB_"))) %>%
      rename_with(~ "CTFIPS",
                  any_of(c("CTFIPS", "FIPS", "TRACT_FIPS")))
    
    # Verify required columns exist after renaming
    required_cols <- c("CTFIPS", "LATITUDE", "LONGITUDE", "DS_O3_PRED")
    missing_cols  <- setdiff(required_cols, names(df))
    if (length(missing_cols) > 0)
      stop(sprintf(
        "Year %d: required column(s) not found: %s\nActual columns: %s",
        year,
        paste(missing_cols, collapse = ", "),
        paste(names(df), collapse = ", ")
      ))
    
    # Parse date — handles both DD-Mon-YYYY and YYYY-MM-DD formats
    date_col <- intersect(c("DATE", "DATE_LOCAL", "OBS_DATE"), names(df))[1]
    if (is.na(date_col))
      stop(sprintf("Year %d: no date column found. Columns: %s",
                   year, paste(names(df), collapse = ", ")))
    
    df <- df %>%
      mutate(date_parsed = lubridate::parse_date_time(
        .data[[date_col]],
        orders = c("dmy", "Ymd", "dmY", "mdY"),
        quiet  = TRUE
      ))
    
    message(sprintf("    %s rows | %s tracts | %s days",
                    format(nrow(df),                   big.mark = ","),
                    format(n_distinct(df$CTFIPS),      big.mark = ","),
                    format(n_distinct(df$date_parsed), big.mark = ",")))
    
    df
  }
  
  message("\nLoading FAQSD ozone data...")
  all_years_data <- purrr::map(years, load_year)
  
  # -- 3. Compute 4th-highest MDA8 per tract per year ------------------------
  # Mirrors the EPA NAAQS design value methodology: the ozone standard is the
  # annual 4th-highest daily MDA8, which smooths out single anomalous events
  # while still capturing the upper tail of the distribution.
  message("\nComputing 4th-highest MDA8 per census tract per year...")
  
  year_dvs <- purrr::map(all_years_data, function(df) {
    df %>%
      group_by(CTFIPS, LATITUDE, LONGITUDE) %>%
      summarise(
        dv_o3_ppb = sort(DS_O3_PRED, decreasing = TRUE)[4],
        .groups   = "drop"
      )
  })
  
  # -- 4. Average design values across years ----------------------------------
  message(sprintf(
    "Averaging 4th-highest MDA8 across %d year(s): %s...",
    length(years), paste(years, collapse = ", ")
  ))
  
  mean_ozone_tract <- bind_rows(year_dvs) %>%
    group_by(CTFIPS, LATITUDE, LONGITUDE) %>%
    summarise(
      mean_ozone = mean(dv_o3_ppb, na.rm = TRUE),
      n_years    = sum(!is.na(dv_o3_ppb)),
      .groups    = "drop"
    ) %>%
    filter(!is.na(mean_ozone))
  
  message(sprintf("  %s tract centroids with valid estimates.",
                  format(nrow(mean_ozone_tract), big.mark = ",")))
  
  # -- 5. Convert tract centroids to sf --------------------------------------
  tracts_sf <- mean_ozone_tract %>%
    sf::st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326)
  
  # -- 6. Compute prison polygon centroids -----------------------------------
  message("Computing prison polygon centroids...")
  
  prison_centroids <- sf_obj %>%
    sf::st_transform(5070) %>%   # Albers Equal Area for accurate centroids
    sf::st_centroid() %>%
    sf::st_transform(4326)
  
  # -- 7. Match each prison centroid to nearest tract centroid ---------------
  message("Matching prisons to nearest tract centroids...")
  
  nearest_idx <- sf::st_nearest_feature(prison_centroids, tracts_sf)
  
  sf_obj$mean_ozone     <- mean_ozone_tract$mean_ozone[nearest_idx]
  sf_obj$matched_CTFIPS <- mean_ozone_tract$CTFIPS[nearest_idx]
  
  match_dist_m <- sf::st_distance(
    prison_centroids,
    tracts_sf[nearest_idx, ],
    by_element = TRUE
  ) %>% as.numeric()
  
  sf_obj$dist_to_tract_m <- round(match_dist_m)
  
  n_far <- sum(match_dist_m > 20000, na.rm = TRUE)
  if (n_far > 0)
    warning(sprintf(
      "%d facilities matched to a tract centroid >20 km away (likely rural AK/HI). Review dist_to_tract_m.",
      n_far
    ))
  
  # -- 8. Assemble output ----------------------------------------------------
  sf_ozone <- sf_obj %>%
    sf::st_drop_geometry() %>%
    dplyr::select(FACILITYID, mean_ozone, matched_CTFIPS, dist_to_tract_m)
  
  message(sprintf(
    "\nDone. %s facilities | mean: %.1f ppb | range: %.1f-%.1f ppb",
    format(nrow(sf_ozone), big.mark = ","),
    mean(sf_ozone$mean_ozone, na.rm = TRUE),
    min(sf_ozone$mean_ozone,  na.rm = TRUE),
    max(sf_ozone$mean_ozone,  na.rm = TRUE)
  ))
  
  # -- 9. Save ----------------------------------------------------------------
  if (save) {
    if (!dir.exists(out_path)) dir.create(out_path, recursive = TRUE)
    out_file <- file.path(out_path, paste0("ozone_faqsd_", Sys.Date(), ".csv"))
    readr::write_csv(sf_ozone, file = out_file)
    message(sprintf("Saved: %s", out_file))
  }
  
  return(dplyr::as_tibble(sf_ozone))
}