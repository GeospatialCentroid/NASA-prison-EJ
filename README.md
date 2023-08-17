# Mapping environmental injustices within the U.S. prison system

This is the working repository for a NASA ROSES-21 A.49 Earth Science Applications: Equity and Environmental Justice funded project (Award No 80NSSC22K1465) titled "Leveraging Earth science data to heighten awareness of environmental injustices within the U.S. prison system".

This repository hosts the workflow used to carry out the spatial analysis, from data retrieval to producing the final dataset that is hosted (here). Below are further details on the repository structure, how to use the code base, and data sources.

Forward any questions reguarding this project and code base to Caitlin Mothes (ccmothes@colostate.edu)

<br/>

## Folder Descriptions

-   `doc/` Project-specific references and metadata. Also includes the NASA-funded project proposal that includes background, objectives and methods of the project.

-   `data/` This folder is stored locally (see Github_Collab_Guide.docx in `doc/` for methods on how to set up a local data folder that syncs to a cloud-hosted folder). All raw, unprocessed data lives in `raw/` and all datasets processed throughout the workflow (using code in `process_data/`) go to `processed/`

- `process-data/` Scripts to process raw data (when needed). Outputs of these scripts go into `data/processed/`

-   `R/` R code for analysis, each formatted as an individual function for each indicator calculation (i.e., all indicators not requiring Earth Engine data sets).

-   `python/` Python code for Google Earth Enginge analyses. Specifically used to calculate canopy cover and land surface temperature variables.

- `outputs/` 

- `analysis/` R code for all post-hoc analysis of final data set.

-   `figures/` Figures produced from analysis scripts.

- `working_scripts/` Old or in progress scripts outside of current workflow. External collaborators can disreguard this folder. 


## General workflow


## Data sources and indicator methods


