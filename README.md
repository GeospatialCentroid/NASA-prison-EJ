# Mapping environmental injustices within the U.S. prison system

This is the working repository for a NASA Equity and Environmental Justice project titled "Leveraging Earth science data to heighten awareness of environmental injustices within the U.S. prison system".

<br/>

**General repository structure:**

    .
    └── NASA-prison-EJ
        ├── doc
        ├── data
        │   ├── raw
        │   └── processed
        ├── python
        │   ├── src
        |   ├── ee
        │   └── py_scratch
        ├── R
        │   ├── src
        │   └── R_scratch
        ├── figs
        ├── README.md
        └── .gitignore

-   `data/` This folder is stored locally (see Github_Collab_Guide.docx in `doc/` for instructions on how to set up local data folder). All raw, unprocessed data lives in `raw/` and all datasets processed throughout the workflow go to `processed/`

-   `doc/` Project-specific references and metadata

-   `python/` Python code for analysis

    -   `src/` Functions to calculate individual indicators

    -   `ee/` Code to import and process data from Google Earth Engine

    -   `py_scratch` Working Python scripts / code outside of the main workflow

-   `R/` R code for analysis

    -   `src/` Functions to calculate individual indicators

    -   `R_scratch` Working R scripts / code outside of the main workflow

-   `figs/` Figures produced from code
