# Mapping environmental injustices within the U.S. prison system

This is the working repository for a NASA ROSES-21 A.49 Earth Science Applications: Equity and Environmental Justice funded project (Award No 80NSSC22K1465) titled "Leveraging Earth science data to heighten awareness of environmental injustices within the U.S. prison system".

This repository hosts the workflow used to carry out the spatial analysis, from data retrieval to producing the final dataset that is hosted (here). Below are further details on the repository structure, how to use the code base, and data sources.

Forward any questions reguarding this project and code base to Caitlin Mothes ([ccmothes\@colostate.edu](mailto:ccmothes@colostate.edu))

<br/>

## Folder Descriptions

-   `doc/` Project-specific references and metadata. Also includes the NASA-funded project proposal that includes background, objectives and methods of the project.

-   `data/` This folder is stored locally (see Github_Collab_Guide.docx in `doc/` for methods on how to set up a local data folder that syncs to a cloud-hosted folder). All raw, unprocessed data lives in `raw/` and all datasets processed throughout the workflow (using code in `process_data/`) go to `processed/` . GEE-processed datasets also live in this `processed/` folder.

-   `process_data/` Scripts to process raw data (when needed). Outputs of these scripts go into `data/processed/`

-   `R/` R code for analysis, each formatted as an individual function for each indicator calculation (i.e., all indicators not requiring Earth Engine data sets).

-   `python/` Python code for Google Earth Engine analyses. Specifically used to calculate canopy cover and land surface temperature variables.

-   `jobs/` Job scripts to run background jobs for each component function (See 'process_components.Rmd' for executing these.

-   `outputs/` Where all outputs from each indicator function, component function and final data frame calculation are stored. Each file is set up to include the date of creation when saved to this folder.

-   `analysis/` R code for all post-hoc analysis of final data set.

-   `figures/` Figures produced from analysis scripts.

-   `working_scripts/` Old or in progress scripts outside of current workflow. External collaborators can disregard this folder.

## File Descriptions

There are a few important files in the root directory:

-   `setup.R` Executing this script will install and load all necessary packages, source all functions, and create a local 'outputs/' directory if it does not already exist.

-   `process_indicators.R / .Rmd` This file (saved as both an R script and R Markdown for user preference) works through executing indicator calculations individually.

-   `process_components.Rmd` This file walks the user through calculating indicators as grouped component scores. It also has an option for executing the component functions as background jobs (as some may take days to full execute due to large datasets and scale of processing).

## General workflow

The main files described above give users the option to run individual indicators or process the entire component scores all at once, and each work through creating a final data frame as the last step.

This workflow is designed to work on ANY spatial polygon `sf` object. While this project specifically studies state and federal US prisons, the code can be applied to any other boundary shapefile, greatly expanding the utility of this code base and allowing for future researchers to analyze other areas of interest (e.g., extend to jails and juvenile detention centers, or calculate measures for other communities/neighborhoods to assess comparisons with risks faces by prisoners).

While some functions and scripts retrieve the datasets directly from the code base, some need to be downloaded manually. The table below provides links to download each of the datasets used in this project, and direct users to the processing script used to clean the raw data download (if necessary).

## Data sources and indicator methods

A full metadata table with data sources, links, indicator methods and data metadata can be found in [doc/indicator_metadata.md](https://github.com/GeospatialCentroid/NASA-prison-EJ/blob/main/doc/indicator_metadata.md)
