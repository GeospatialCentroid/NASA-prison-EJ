# Pull in Meta high res population density data: https://ai.meta.com/ai-for-good/datasets/high-resolution-population-density-maps/
## Data as of 2019-2020

source("setup.R")

## First pull just for California -----------------

# Get California boundary ----------------------
ca <- tigris::states(cb = TRUE, year = 2020) |>
  subset(STUSPS == "CA") |>
  sf::st_transform(4326)  # match HRSL CRS (WGS84)

ca_ext <- terra::ext(sf::st_bbox(ca)[c("xmin","xmax","ymin","ymax")])

# Read HRSL total population VRT directly from S3 ----
# Uses the global VRT mosaic — no AWS credentials needed
hrsl_url <- "/vsicurl/https://dataforgood-fb-data.s3.amazonaws.com/hrsl-cogs/hrsl_general/hrsl_general-latest.vrt"

pop <- terra::rast(hrsl_url)

# Crop and mask to California ----
ca_vect  <- terra::vect(ca)
pop_ca   <- terra::crop(pop, ca_ext) |> terra::mask(ca_vect)

# Save for CA specific analysis/exploration
terra::writeRaster(pop_ca, "data/phase2/raw/population/ca_30m_pop_density_hrsl_2020.tif", overwrite = TRUE)
