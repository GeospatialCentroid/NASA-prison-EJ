# Set up script to execute workflow

# Load libraries ---------------------------------------------------------------
## function to load/install packages (reproducible across machines/local systems)
package_load <- function(x) {
  for (i in 1:length(x)) {
    if (!x[i] %in% installed.packages()) {
      install.packages(x[i])
    }
    library(x[i], character.only = TRUE)
  }
}


## list all required packages
packages <- c('tidyverse',
              'sf',
              'terra'
)

## load in packages
package_load(packages)

# Source functions -------------------------------------------------------------
purrr::map(list.files("R/", full.names = TRUE), source)
