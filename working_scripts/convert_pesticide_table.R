#' Converting the CalEnviroScreen PDF table to a dataframe of pesticides
#'
#' @param file The file path pointing to the subset of the CalEnviroScreen PDF report with the pesticides table
#' @param save Whether to save (TRUE) the resulting dataframe (as .csv) or not (FALSE)
#' @param out_path If `save = TRUE`, the file path to the folder to save the output csv to
convert_pesticide_table <- function(file = "data/raw/pesticides/CalEnviroScreen40_PESTICIDE_LIST.pdf",
                          save = TRUE, out_path = "data/processed/pesticides") {
  # Initialize variables
  cal_pest <- extract_tables(file)
  cal_pest_all <- list()

  # Clean and stitch together pages of table
  for (i in 1:length(cal_pest)) {
    df_df <- data.frame(cal_pest[i])
    df_cut <- df_df[-(1:3), ]

    cal_pest_all[[i]] <- df_cut
  }

  cal_pest <- cal_pest_all %>%
    bind_rows(.)

  # Clean extra blank spaces, rename variables
  cal_pest_clean <- cal_pest %>%
    filter(if_all(.cols = everything(), ~ .x != "")) %>%
    rename_all(., ~ c("pesticide_active_ingredient", "use_2017_19_lbs", "enviroscreen_rank"))

  # Final list of pesticides from CalEnviroScreen
  cal_pest_list <- tolower(unique(cal_pest_clean$pesticide_active_ingredient))

  cal_pest_df <- as.data.frame(cal_pest_list)

  if (save == TRUE) {
    write_csv(cal_pest_df, paste0(writePath, "pesticide_list.csv"))
  }
}
