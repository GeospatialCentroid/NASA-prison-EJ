# Pull a sample of 5,000 data point using the california raster drawn from Meta's
#  HRSL raster file. 

# After sampling these points, next apply a buffer to each point and remove 
#  intersecting points. 

# Finally add an object_id feature for further analysis. 

source("setup.R")

## First pull a sample of 5,000 points without replacement using population -----

#read in califorina raster 
ca_pop_raster <- rast("data/phase2/raw/population/ca_30m_pop_density_hrsl_2020.tif")

#aggregate first, then round
pop_aggregate <- ca_pop_raster %>% 
  terra::aggregate(fact = 10, 
                   fun = sum, 
                   na.rm = TRUE)

#next, let's round to the nearest integer
pop_aggregate <- terra::round(pop_aggregate)

#now, let's drop all 0's. 
pop_aggregate[pop_aggregate==0] <- NA

#next, let's sample 
set.seed(513)
#to speed up calculations, lets first convert values to a data frame
pop_vals <- as.data.frame(pop_aggregate,cells=TRUE, na.rm = TRUE)
colnames(pop_vals) <- c("cell", "pop")

#add a weight/probability column
pop_vals <- pop_vals %>% 
  filter(pop>0) %>% #remove zeros if values weren't changed to NA's
  mutate(prob = pop/sum(pop))

#now let's attempt to sample points without replacement
sampled_points <- sample(
  x = pop_vals$cell,
  size = 5000,
  replace = FALSE, 
  prob = pop_vals$prob
)

# keep sampled rows INCLUDING population values
sampled_df <- pop_vals %>%
  filter(cell %in% sampled_points)
# add coordinates
coords <- xyFromCell(pop_aggregate, sampled_df$cell)

sampled_df <- sampled_df %>%
  mutate(object_id = 1:5000) %>% 
  mutate(
    lon = coords[,1],
    lat = coords[,2]
  )

# convert to sf object
sampled_sf <- st_as_sf(
  sampled_df,
  coords = c("lon", "lat"),
  crs = crs(pop_aggregate)
)

## Second, add a buffer to each of these points. -----------------
sampled_sf <- sampled_sf %>% st_buffer(169)

#reorder 
sampled_sf <- sampled_sf %>% select(object_id,
                                    cell,
                                    pop,
                                    prob,
                                    geometry)

## Third, remove intersections with prisons.  --------------
#read in prisons and filter to california
ca_prisons <- read_sf("data/phase2/processed/prisons/study_prisons.gpkg") %>% 
  filter(STATE == "CA")

# keep track/cluster intersections
cleared_sample <- st_difference(sampled_sf, st_union(ca_prisons))

# remove points that intersect with a prison
cleared_sample <- cleared_sample[!st_is_empty(cleared_sample), ]

# next, remove self intersections and keep points
intersections <- st_intersects(cleared_sample) #cluster intersections
group_ids <- sapply(intersections, function(x) x[1]) #return only the first entry

# now keep only distinct values 
final_sample <- cleared_sample %>% 
  mutate(group_id = group_ids) %>%
  distinct(group_id, .keep_all = TRUE) %>%
  select(-group_id)

### finally save these data for future analysis
write_sf(final_sample,"data/ca_sample/ca_residences.gpkg")
