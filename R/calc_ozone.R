#' Calculate ozone exposure using EPA FAQSD Downscaler data
#'
#' Computes the 3-year average of annual 4th-highest daily 8-hour maximum ozone
#' (MDA8) for each facility polygon using the EPA Fused Air Quality Surface Using
#' Downscaling (FAQSD) product.
#'
#' FAQSD fuses AQS monitor observations with 12 km CMAQ model output via a
#' Bayesian space-time downscaler. Output is one value per 2010 Census tract
#' centroid per day. Spatial matching finds the nearest tract centroid to the
#' closest point on each facility polygon boundary (not the polygon centroid),
#' then pulls that tract's mean MDA8 value.
#'
#' Expected file path structure:
#'   data/phase2/raw/ozone/{year}_ozone_daily_8hour_maximum.txt.gz
#'
#' Data source:
#'   EPA HESC RSIG FAQSD — https://www.epa.gov/hesc/rsig-related-downloadable-data-files
#'   Columns: Date, FIPS, Longitude, Latitude,
#'            ozone_daily_8hour_maximum(ppb), ozone_daily_8hour_maximum_stderr(ppb)
#'
#' @param sf_obj    An sf object of facility polygons (any CRS; reprojected internally).
#' @param folder    Path to folder containing the FAQSD .txt.gz files.
#'                  Default "data/phase2/raw/ozone".
#' @param years     Integer vector of years to average across.
#'                  Default c(2019, 2021, 2022) skips 2020 (anomalous COVID emissions).
#' @param id_column A string specifying the name of the unique facility identifier column
#'                  (e.g., "FACILITYID" for prisons, "object_id" for ICE detention facilities).
#'                  Default is "FACILITYID".
#' @param save      Logical. Save results as CSV. Default TRUE.
#' @param out_path  Directory for the saved CSV. Default "outputs/".
#'
#' @return A tibble with one row per facility:
#'   {id_column}, mean_ozone (ppb), matched_fips, dist_to_tract_m
#'
#' @examples
#' \dontrun{
#' prisons <- sf::st_read("study_prisons.shp")
#' result  <- calc_ozone(prisons)
#' result  <- calc_ozone(prisons, years = c(2019, 2021, 2022),
#'                       folder = "data/phase2/raw/ozone")
#' }

calc_ozone <- function(
    sf_obj,
    folder   = "data/phase2/raw/ozone",
    years    = c(2019, 2021, 2022),
    id_column = "FACILITYID",
    save     = TRUE,
    out_path = "outputs/"
) {
  
  # -- 1. Validate inputs -------------------------------------------------------
  if (2020 %in% years)
    warning(
      "Year 2020 included. COVID-related emission reductions produced ",
      "anomalously low ozone precursor levels. Consider excluding it."
    )
  
  # -- 2. Load and parse FAQSD data for each year -------------------------------
  load_year <- function(year) {
    
    filepath <- file.path(
      folder,
      sprintf("%d_ozone_daily_8hour_maximum.txt.gz", year)
    )
    if (!file.exists(filepath))
      stop(sprintf("File not found for year %d:\n  %s", year, filepath))
    
    message(sprintf("  [%d] Reading %s", year, basename(filepath)))
    
    df <- vroom::vroom(
      filepath,
      delim          = ",",
      col_types      = vroom::cols(
        .default                                = vroom::col_character(),
        Longitude                               = vroom::col_double(),
        Latitude                                = vroom::col_double(),
        `ozone_daily_8hour_maximum(ppb)`        = vroom::col_double(),
        `ozone_daily_8hour_maximum_stderr(ppb)` = vroom::col_double()
      ),
      show_col_types = FALSE,
      na             = c("", "NA", "-999", "-9999")
    ) |>
      janitor::clean_names()
    
    df <- df |>
      dplyr::mutate(
        latitude                             = as.numeric(latitude),
        longitude                            = as.numeric(longitude),
        ozone_daily_8hour_maximum_ppb        = as.numeric(ozone_daily_8hour_maximum_ppb),
        ozone_daily_8hour_maximum_stderr_ppb = as.numeric(ozone_daily_8hour_maximum_stderr_ppb)
      )
    
    required_cols <- c("date", "latitude", "longitude", "fips",
                       "ozone_daily_8hour_maximum_ppb",
                       "ozone_daily_8hour_maximum_stderr_ppb")
    missing_cols <- setdiff(required_cols, names(df))
    if (length(missing_cols) > 0)
      stop(sprintf(
        "Year %d: required column(s) not found: %s\nActual columns: %s",
        year,
        paste(missing_cols, collapse = ", "),
        paste(names(df), collapse = ", ")
      ))
    
    df |> dplyr::select(fips, latitude, longitude, ozone_daily_8hour_maximum_ppb)
  }
  
  message("\nLoading FAQSD ozone data...")
  all_years_data <- purrr::map(years, load_year)
  
  # -- 3. Compute 4th-highest MDA8 per tract per year --------------------------
  message("\nComputing 4th-highest MDA8 per census tract per year...")
  
  fourth_highest <- function(x) {
    x <- sort(x[!is.na(x)], decreasing = TRUE)
    if (length(x) >= 4) x[4] else NA_real_
  }
  
  year_dvs <- purrr::map(all_years_data, function(df) {
    dt <- data.table::as.data.table(df)
    dt[, .(
      dv_o3_ppb = fourth_highest(ozone_daily_8hour_maximum_ppb),
      latitude  = latitude[1],
      longitude = longitude[1]
    ), by = fips]
  })
  
  # -- 4. Average design values across years ------------------------------------
  mean_ozone_tract <- data.table::rbindlist(year_dvs) |>
    dplyr::group_by(fips, latitude, longitude) |>
    dplyr::summarise(
      mean_ozone = mean(dv_o3_ppb, na.rm = TRUE),
      n_years    = sum(!is.na(dv_o3_ppb)),
      .groups    = "drop"
    ) |>
    dplyr::filter(!is.na(mean_ozone))
  
  message(sprintf("  %s tract centroids with valid estimates.",
                  format(nrow(mean_ozone_tract), big.mark = ",")))
  
  # -- 5. Convert tract centroids to sf (projected) ----------------------------
  tracts_sf <- mean_ozone_tract |>
    sf::st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |>
    sf::st_transform(5070)
  
  # -- 6. Project facility polygons to Albers Equal Area -----------------------
  message("Projecting facility polygons...")
  facilities_proj <- sf::st_transform(sf_obj, 5070)
  
  # -- 7. Find nearest tract centroid to each facility boundary ----------------
  message("Matching facility boundaries to nearest tract centroids...")
  
  nearest_idx <- sf::st_nearest_feature(facilities_proj, tracts_sf)
  
  dist_m <- sf::st_distance(
    facilities_proj,
    tracts_sf[nearest_idx, ],
    by_element = TRUE
  ) |> as.numeric()
  
  n_far <- sum(dist_m > 20000, na.rm = TRUE)
  if (n_far > 0)
    warning(sprintf(
      "%d facilities matched to a tract centroid >20 km away. Review dist_to_tract_m.",
      n_far
    ))
  
  # -- 8. Assemble output -------------------------------------------------------
  result <- sf::st_drop_geometry(sf_obj) |>
    dplyr::transmute(
      !!sym(id_column) := !!sym(id_column),
      mean_ozone       = mean_ozone_tract$mean_ozone[nearest_idx],
      matched_fips     = mean_ozone_tract$fips[nearest_idx],
      dist_to_tract_m  = round(dist_m)
    )
  
  message(sprintf(
    "\nDone. %s facilities | mean: %.1f ppb | range: %.1f-%.1f ppb",
    format(nrow(result), big.mark = ","),
    mean(result$mean_ozone, na.rm = TRUE),
    min(result$mean_ozone,  na.rm = TRUE),
    max(result$mean_ozone,  na.rm = TRUE)
  ))
  
  # -- 9. Save ------------------------------------------------------------------
  if (save) {
    if (!dir.exists(out_path)) dir.create(out_path, recursive = TRUE)
    out_file <- file.path(out_path, paste0("ozone_", Sys.Date(), ".csv"))
    readr::write_csv(result, file = out_file)
    message(sprintf("Saved: %s", out_file))
  }
  
  dplyr::as_tibble(result)
}