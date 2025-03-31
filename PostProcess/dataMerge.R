# This codefile has been automatically generated using Copilot from the original Python script dataMerge.py
# It has not yet been reviewed or tested for correctness and reasonability.

##### setup
####################################################################################################################
####################################################################################################################

### package imports
##########################################################
library(tidyverse)
library(lubridate)
library(sf)
library(arrow)
library(geosphere)
library(ggplot2)
library(seaborn)
library(stats)
library(data.table)

### path locations & environmental variables
##########################################################

### define project folder path 
githubRepo_path <- "C:/Users/U8017882/OneDrive - USQ/Documents/01_projects/02_LSMS_cropSeasons/LSMS_multiplecropping"

# set working directory to project path
setwd(githubRepo_path)

##### load country datasets and metadata
####################################################################################################################
####################################################################################################################

# directory containing final datasets and metadata
outData_dir <- file.path(githubRepo_path, 'out')

# load datasets into list
dataset_dct <- list(
  ETH_all_pd = read.csv(file.path(outData_dir, 'ETH_allWaves.csv')),
  MLI_all_pd = read.csv(file.path(outData_dir, 'MLI_allWaves.csv')),
  MWI_all_pd = read.csv(file.path(outData_dir, 'MWI_allWaves.csv')),
  UGA_many_pd = read.csv(file.path(outData_dir, 'UGA_allWaves.csv')),
  UGA_2011_pd = read.csv(file.path(outData_dir, 'uganda11-12.csv')),
  UGA_2013_pd = read.csv(file.path(outData_dir, 'uganda13-14.csv')),
  NIG_2015_pd = read.csv(file.path(outData_dir, 'Nigeria_GHS_W3_results.csv')),
  NIG_2018_pd = read.csv(file.path(outData_dir, 'Nigeria_GHS_W4_results.csv')),
  NER_2011_pd = read.csv(file.path(outData_dir, 'Niger11-12.csv')),
  NER_2014_pd = read.csv(file.path(outData_dir, 'NER_2014-15.csv'))
)

# dataset template
dataset_template_pd <- read.csv(file.path(githubRepo_path, 'documentation/dataset_template/dataset_template.csv'))

# target columns list
targetCols_dataset_lst <- colnames(dataset_template_pd)

# load metadata into list
metadata_dct <- list(
  ETH_all_pd = read.csv(file.path(outData_dir, 'ETH_allWaves_metadata.csv')),
  MLI_2014_pd = read.csv(file.path(outData_dir, 'MLI_2014-15_metadata.csv'), sep = ';', dec = ",", fileEncoding = 'ISO-8859-1'),
  MLI_2017_pd = read.csv(file.path(outData_dir, 'MLI_2017-18_metadata.csv'), sep = ';', dec = ",", fileEncoding = 'ISO-8859-1'),
  MWI_all_pd = read.csv(file.path(outData_dir, 'MWI_allWaves_metadata.csv')),
  UGA_2011_pd = read.csv(file.path(outData_dir, 'uganda11-12_meta.csv')),
  UGA_2013_pd = read.csv(file.path(outData_dir, 'uganda13-14_meta.csv')),
  UGA_many_pd = read.csv(file.path(outData_dir, 'UGA_allWaves_metadata.csv')),
  NIG_2015_pd = read.csv(file.path(outData_dir, 'NGA_2016_metadata.csv')),
  NIG_2018_pd = read.csv(file.path(outData_dir, 'NGA_2018_metadata.csv')),
  NER_2011_pd = read.csv(file.path(outData_dir, 'Niger11-12_meta.csv')),
  NER_2014_pd = read.csv(file.path(outData_dir, 'NER_2014-15_metadata.csv'), sep = ';', dec = ",", fileEncoding = 'ISO-8859-1')
)

# metadata template
metadata_template_pd <- read.csv(file.path(githubRepo_path, 'documentation/metadata_template/metadata_template.csv'))

# target columns list
targetCols_metadata_lst <- colnames(metadata_template_pd)

##### inspect datasets & metadata
####################################################################################################################
####################################################################################################################

### inspect datasets
##########################################################

## dictionary with descriptive information
datasetsInspect_dct <- list()

# add keys to dictionary
for (key in names(dataset_dct)) {
  datasetsInspect_dct[[substr(key, 1, nchar(key) - 3)]] <- list()
}

### inspect missing columns

# loop over datasets
for (df_string in names(dataset_dct)) {
  df <- dataset_dct[[df_string]]
  
  # list of missing columns
  missingCols_lst_tmp <- c()
  # list of additional, non-target columns
  nontargetCols_dataset_lst_tmp <- c()
  
  # loop over target columns
  for (targetCol in targetCols_dataset_lst) {
    # check if dataset contains target column
    if (!(targetCol %in% colnames(df))) {
      # if missing: record column-name as missing
      missingCols_lst_tmp <- c(missingCols_lst_tmp, targetCol)
    }
  }
  
  # loop over dataset columns
  for (datasetCol in colnames(df)) {
    # check if dataset-column is part of target columns
    if (!(datasetCol %in% targetCols_dataset_lst)) {
      nontargetCols_dataset_lst_tmp <- c(nontargetCols_dataset_lst_tmp, datasetCol)
    }
  }
  
  # store list of missing columns to descriptive dictionary
  datasetsInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$missingCols_lst <- missingCols_lst_tmp
  # store list of additional, non-target columns to descriptive dictionary
  datasetsInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$nontargetCols_dataset_lst <- nontargetCols_dataset_lst_tmp
}

### inspect metadata
##########################################################

## dictionary with descriptive information
metadataInspect_dct <- list()

# add keys to dictionary
for (key in names(metadata_dct)) {
  metadataInspect_dct[[substr(key, 1, nchar(key) - 3)]] <- list()
}

### inspect missing columns

# loop over metadata-datasets
for (df_string in names(metadata_dct)) {
  df <- metadata_dct[[df_string]]
  
  # list of missing columns
  missingCols_lst_tmp <- c()
  # list of additional, non-target columns
  nontargetCols_metadata_lst_tmp <- c()
  
  # loop over target columns
  for (targetCol in targetCols_metadata_lst) {
    # check if metadata contains target column
    if (!(targetCol %in% colnames(df))) {
      # if missing: record column-name as missing
      missingCols_lst_tmp <- c(missingCols_lst_tmp, targetCol)
    }
  }
  
  # loop over metadata columns
  for (metadataCol in colnames(df)) {
    # check if metadata-column is part of target columns
    if (!(metadataCol %in% targetCols_metadata_lst)) {
      nontargetCols_metadata_lst_tmp <- c(nontargetCols_metadata_lst_tmp, metadataCol)
    }
  }
  
  # store list of missing columns to descriptive dictionary
  metadataInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$missingCols_lst <- missingCols_lst_tmp
  # store list of additional, non-target columns to descriptive dictionary
  metadataInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$nontargetCols_dataset_lst <- nontargetCols_metadata_lst_tmp
}

##### harmonize datasets & metadata
####################################################################################################################
####################################################################################################################

### harmonize datasets
##########################################################

## Niger (2011)
##########

# rename variables to correspond to template
dataset_dct[['NER_2011_pd']] <- dataset_dct[['NER_2011_pd']] %>%
  rename(
    lon = long,
    harvest_month = harvesting_month,
    harvest_year = harvesting_year,
    dataset_name = source
  )

# overwrite GPS_level value: using harmonised naming convention
dataset_dct[['NER_2011_pd']]$GPS_level <- replace(dataset_dct[['NER_2011_pd']]$GPS_level, dataset_dct[['NER_2011_pd']]$GPS_level == 'Grappe', 3)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NER_2011_pd']]$adm3 <- NA
dataset_dct[['NER_2011_pd']]$adm4 <- NA
dataset_dct[['NER_2011_pd']]$harvest_month_begin <- NA
dataset_dct[['NER_2011_pd']]$harvest_year_begin <- NA
dataset_dct[['NER_2011_pd']]$harvest_month_end <- NA
dataset_dct[['NER_2011_pd']]$harvest_year_end <- NA

# drop redundant variables
dataset_dct[['NER_2011_pd']] <- dataset_dct[['NER_2011_pd']] %>%
  select(-grappe, -plotNbr, -cropID)

# preliminarily, set outstanding variables to NaN
dataset_dct[['NER_2011_pd']]$season <- NA

## Nigeria (2015)
##########

# drop redundant variables
dataset_dct[['NIG_2015_pd']] <- dataset_dct[['NIG_2015_pd']] %>%
  select(-wave, -dm_gender, -gps_meas)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NIG_2015_pd']]$fieldID <- NA

# set redundant variables to NaN
dataset_dct[['NIG_2015_pd']]$harvest_year <- NA
dataset_dct[['NIG_2015_pd']]$harvest_month <- NA

## Nigeria (2018)
##########

# rename variables to correspond to template
dataset_dct[['NIG_2018_pd']] <- dataset_dct[['NIG_2018_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude
  )

# drop redundant variables
dataset_dct[['NIG_2018_pd']] <- dataset_dct[['NIG_2018_pd']] %>%
  select(-wave, -dm_gender, -gps_meas)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NIG_2018_pd']]$fieldID <- NA

# set redundant variables to NaN
dataset_dct[['NIG_2018_pd']]$harvest_year <- NA
dataset_dct[['NIG_2018_pd']]$harvest_month <- NA

## Uganda (2011)
##########

# rename variables to correspond to template
dataset_dct[['UGA_2011_pd']] <- dataset_dct[['UGA_2011_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude,
    dataset_name = source
  )

# set variables genuinely missing in original dataset to NaN
dataset_dct[['UGA_2011_pd']]$fieldID <- NA

## Uganda (2013)
##########

# rename variables to correspond to template
dataset_dct[['UGA_2013_pd']] <- dataset_dct[['UGA_2013_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude,
    dataset_name = source
  )

# set variables genuinely missing in original dataset to NaN
dataset_dct[['UGA_2013_pd']]$fieldID <- NA

# correct variable name of fully missing variable to correspond to template
dataset_dct[['UGA_2013_pd']] <- dataset_dct[['UGA_2013_pd']] %>%
  rename(
    plot_area_measured_ha = plot_area_measured
  )

### harmonize metadata
##########################################################

## Niger (2011)
##########

# complete missing variable-name value (copying value from unnamed column that otherwise only contains duplicates)
metadata_dct[['NER_2011_pd']]$varName_harmonized[metadata_dct[['NER_2011_pd']]$varName_source == 'as02bq03'] <- 'plotNbr'

# drop redundant variables: unnamed columns
metadata_dct[['NER_2011_pd']] <- metadata_dct[['NER_2011_pd']] %>%
  select(-starts_with('Unnamed'))

# overwrite dataset_name
metadata_dct[['NER_2011_pd']]$dataset_name <- "NER_2011_ECVMA_v01_M"

# overwrite dataset_doi
metadata_dct[['NER_2011_pd']]$dataset_doi <- "https://doi.org/10.48529/bp16-s524"

# rename variables to correspond to template
metadata_dct[['NER_2011_pd']]$varName_harmonized <- recode(metadata_dct[['NER_2011_pd']]$varName_harmonized,
  'latitude' = 'lat',
  'longitude' = 'lon'
)

# drop redundant variable-values
metadata_dct[['NER_2011_pd']] <- metadata_dct[['NER_2011_pd']] %>%
  filter(varName_harmonized != 'plotNbr')

## Nigeria (2015)
##########

# set missing statistics-variable to NaN
metadata_dct[['NIG_2015_pd']]$pctMissing_harmonized <- NA
metadata_dct[['NIG_2015_pd']]$pctMissing_source <- NA

## Nigeria (2018)
##########

# set missing statistics-variable to NaN
metadata_dct[['NIG_2018_pd']]$pctMissing_harmonized <- NA
metadata_dct[['NIG_2018_pd']]$pctMissing_source <- NA

##### merge datasets & metadata
####################################################################################################################
####################################################################################################################

### merge datasets
##########################################################

# load all individual dataframes into single dataframe
allData_pd <- bind_rows(dataset_dct)

# drop rows that are NaN across all columns
allData_pd <- allData_pd %>%
  drop_na(everything())

# save to disk
write.csv(allData_pd, file.path(githubRepo_path, 'PostProcess', 'data_merged.csv'), row.names = FALSE)
# write.csv(allData_pd, file.path(githubRepo_path, 'PostProcess', paste0('data_merged_', format(Sys.Date(), '%Y%m%d'), '.csv')), row.names = FALSE)

### merge metadata
##########################################################

# load all individual metadata-files into single dataframe
allMetadata_pd <- bind_rows(metadata_dct)

# drop rows that are NaN across all columns
allMetadata_pd <- allMetadata_pd %>%
  drop_na(everything())

# save to disk
write.csv(allMetadata_pd, file.path(githubRepo_path, 'PostProcess', 'metadata_merged.csv'), row.names = FALSE)
# write.csv(allMetadata_pd, file.path(githubRepo_path, 'PostProcess', paste0('metadata_merged_', format(Sys.Date(), '%Y%m%d'), '.csv')), row.names = FALSE)

##### explore datasets & metadata
####################################################################################################################
####################################################################################################################

## overall descriptive statistics
##########

# dataset of descriptive stats
dataDescription_dct <- list()

# loop over datasets
for (dataset_name in unique(allData_pd$dataset_name)) {
  # subset to single dataset
  df_tmp <- allData_pd %>%
    filter(dataset_name == !!dataset_name)
  
  ## generate df of descriptive stats
  stats_pd <- df_tmp %>%
    summarise_all(list(
      dtype = ~class(.),
      Obs = ~n(),
      Perc_NaN = ~mean(is.na(.)) * 100
    ))
  
  ## append descriptive stats to dct
  dataDescription_dct[[dataset_name]] <- stats_pd
}

## review: crop_area_share
##########

# delete storage container (if available from previous iteration)
if (exists("cropAreaShare_pd")) {
  rm(cropAreaShare_pd)
}

# loop over datasets
for (dataset_name in unique(allData_pd$dataset_name)) {
  # subset to single dataset
  df_tmp <- allData_pd %>%
    filter(dataset_name == !!dataset_name)
  
  # get descriptive stats for crop_area_share
  stats_srs <- df_tmp %>%
    summarise(
      dtype = class(crop_area_share),
      Obs = n(),
      Perc_NaN = mean(is.na(crop_area_share)) * 100
    )
  
  # rename series
  names(stats_srs) <- dataset_name
  
  ## append descriptive stats to storage
  if (!exists("cropAreaShare_pd")) {
    cropAreaShare_pd <- stats_srs
  } else {
    cropAreaShare_pd <- bind_cols(cropAreaShare_pd, stats_srs)
  }
}

## review: season
##########

# delete storage container (if available from previous iteration)
if (exists("season_pd")) {
  rm(season_pd)
}

# loop over datasets
for (dataset_name in unique(allData_pd$dataset_name)) {
  # subset to single dataset
  df_tmp <- allData_pd %>%
    filter(dataset_name == !!dataset_name)
  
  # get descriptive stats for season
  stats_srs <- df_tmp %>%
    summarise(
      dtype = class(season),
      Obs = n(),
      Perc_NaN = mean(is.na(season)) * 100
    )
  
  # rename series
  names(stats_srs) <- dataset_name
  
  ## append descriptive stats to storage
  if (!exists("season_pd")) {
    season_pd <- stats_srs
  } else {
    season_pd <- bind_cols(season_pd, stats_srs)
  }
}

## review: harvest_month_begin
##########

# delete storage container (if available from previous iteration)
if (exists("harvestMonthBegin_pd")) {
  rm(harvestMonthBegin_pd)
}

# loop over datasets
for (dataset_name in unique(allData_pd$dataset_name)) {
  # subset to single dataset
  df_tmp <- allData_pd %>%
    filter(dataset_name == !!dataset_name)
  
  # get descriptive stats for harvest_month_begin
  stats_srs <- df_tmp %>%
    summarise(
      dtype = class(harvest_month_begin),
      Obs = n(),
      Perc_NaN = mean(is.na(harvest_month_begin)) * 100
    )
  
  # rename series
  names(stats_srs) <- dataset_name
  
  ## append descriptive stats to storage
  if (!exists("harvestMonthBegin_pd")) {
    harvestMonthBegin_pd <- stats_srs
  } else {
    harvestMonthBegin_pd <- bind_cols(harvestMonthBegin_pd, stats_srs)
  }
}

## review: planting_month
##########

# delete storage container (if available from previous iteration)
if (exists("planting_month_pd")) {
  rm(planting_month_pd)
}

# loop over datasets
for (dataset_name in unique(allData_pd$dataset_name)) {
  # subset to single dataset
  df_tmp <- allData_pd %>%
    filter(dataset_name == !!dataset_name)
  
  # get descriptive stats for planting_month
  stats_srs <- df_tmp %>%
# filepath: c:\Users\U8017882\OneDrive - USQ\Documents\01_projects\02_LSMS_cropSeasons\LSMS_multiplecropping\PostProcess\dataMerge.R
# Translate the following Python code to R  

##### setup
####################################################################################################################
####################################################################################################################

### package imports
##########################################################
library(tidyverse)
library(lubridate)
library(sf)
library(arrow)
library(geosphere)
library(ggplot2)
library(seaborn)
library(stats)
library(data.table)

### path locations & environmental variables
##########################################################

### define project folder path 
githubRepo_path <- "C:/Users/U8017882/OneDrive - USQ/Documents/01_projects/02_LSMS_cropSeasons/LSMS_multiplecropping"

# set working directory to project path
setwd(githubRepo_path)

##### load country datasets and metadata
####################################################################################################################
####################################################################################################################

# directory containing final datasets and metadata
outData_dir <- file.path(githubRepo_path, 'out')

# load datasets into list
dataset_dct <- list(
  ETH_all_pd = read.csv(file.path(outData_dir, 'ETH_allWaves.csv')),
  MLI_all_pd = read.csv(file.path(outData_dir, 'MLI_allWaves.csv')),
  MWI_all_pd = read.csv(file.path(outData_dir, 'MWI_allWaves.csv')),
  UGA_many_pd = read.csv(file.path(outData_dir, 'UGA_allWaves.csv')),
  UGA_2011_pd = read.csv(file.path(outData_dir, 'uganda11-12.csv')),
  UGA_2013_pd = read.csv(file.path(outData_dir, 'uganda13-14.csv')),
  NIG_2015_pd = read.csv(file.path(outData_dir, 'Nigeria_GHS_W3_results.csv')),
  NIG_2018_pd = read.csv(file.path(outData_dir, 'Nigeria_GHS_W4_results.csv')),
  NER_2011_pd = read.csv(file.path(outData_dir, 'Niger11-12.csv')),
  NER_2014_pd = read.csv(file.path(outData_dir, 'NER_2014-15.csv'))
)

# dataset template
dataset_template_pd <- read.csv(file.path(githubRepo_path, 'documentation/dataset_template/dataset_template.csv'))

# target columns list
targetCols_dataset_lst <- colnames(dataset_template_pd)

# load metadata into list
metadata_dct <- list(
  ETH_all_pd = read.csv(file.path(outData_dir, 'ETH_allWaves_metadata.csv')),
  MLI_2014_pd = read.csv(file.path(outData_dir, 'MLI_2014-15_metadata.csv'), sep = ';', dec = ",", fileEncoding = 'ISO-8859-1'),
  MLI_2017_pd = read.csv(file.path(outData_dir, 'MLI_2017-18_metadata.csv'), sep = ';', dec = ",", fileEncoding = 'ISO-8859-1'),
  MWI_all_pd = read.csv(file.path(outData_dir, 'MWI_allWaves_metadata.csv')),
  UGA_2011_pd = read.csv(file.path(outData_dir, 'uganda11-12_meta.csv')),
  UGA_2013_pd = read.csv(file.path(outData_dir, 'uganda13-14_meta.csv')),
  UGA_many_pd = read.csv(file.path(outData_dir, 'UGA_allWaves_metadata.csv')),
  NIG_2015_pd = read.csv(file.path(outData_dir, 'NGA_2016_metadata.csv')),
  NIG_2018_pd = read.csv(file.path(outData_dir, 'NGA_2018_metadata.csv')),
  NER_2011_pd = read.csv(file.path(outData_dir, 'Niger11-12_meta.csv')),
  NER_2014_pd = read.csv(file.path(outData_dir, 'NER_2014-15_metadata.csv'), sep = ';', dec = ",", fileEncoding = 'ISO-8859-1')
)

# metadata template
metadata_template_pd <- read.csv(file.path(githubRepo_path, 'documentation/metadata_template/metadata_template.csv'))

# target columns list
targetCols_metadata_lst <- colnames(metadata_template_pd)

##### inspect datasets & metadata
####################################################################################################################
####################################################################################################################

### inspect datasets
##########################################################

## dictionary with descriptive information
datasetsInspect_dct <- list()

# add keys to dictionary
for (key in names(dataset_dct)) {
  datasetsInspect_dct[[substr(key, 1, nchar(key) - 3)]] <- list()
}

### inspect missing columns

# loop over datasets
for (df_string in names(dataset_dct)) {
  df <- dataset_dct[[df_string]]
  
  # list of missing columns
  missingCols_lst_tmp <- c()
  # list of additional, non-target columns
  nontargetCols_dataset_lst_tmp <- c()
  
  # loop over target columns
  for (targetCol in targetCols_dataset_lst) {
    # check if dataset contains target column
    if (!(targetCol %in% colnames(df))) {
      # if missing: record column-name as missing
      missingCols_lst_tmp <- c(missingCols_lst_tmp, targetCol)
    }
  }
  
  # loop over dataset columns
  for (datasetCol in colnames(df)) {
    # check if dataset-column is part of target columns
    if (!(datasetCol %in% targetCols_dataset_lst)) {
      nontargetCols_dataset_lst_tmp <- c(nontargetCols_dataset_lst_tmp, datasetCol)
    }
  }
  
  # store list of missing columns to descriptive dictionary
  datasetsInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$missingCols_lst <- missingCols_lst_tmp
  # store list of additional, non-target columns to descriptive dictionary
  datasetsInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$nontargetCols_dataset_lst <- nontargetCols_dataset_lst_tmp
}

### inspect metadata
##########################################################

## dictionary with descriptive information
metadataInspect_dct <- list()

# add keys to dictionary
for (key in names(metadata_dct)) {
  metadataInspect_dct[[substr(key, 1, nchar(key) - 3)]] <- list()
}

### inspect missing columns

# loop over metadata-datasets
for (df_string in names(metadata_dct)) {
  df <- metadata_dct[[df_string]]
  
  # list of missing columns
  missingCols_lst_tmp <- c()
  # list of additional, non-target columns
  nontargetCols_metadata_lst_tmp <- c()
  
  # loop over target columns
  for (targetCol in targetCols_metadata_lst) {
    # check if metadata contains target column
    if (!(targetCol %in% colnames(df))) {
      # if missing: record column-name as missing
      missingCols_lst_tmp <- c(missingCols_lst_tmp, targetCol)
    }
  }
  
  # loop over metadata columns
  for (metadataCol in colnames(df)) {
    # check if metadata-column is part of target columns
    if (!(metadataCol %in% targetCols_metadata_lst)) {
      nontargetCols_metadata_lst_tmp <- c(nontargetCols_metadata_lst_tmp, metadataCol)
    }
  }
  
  # store list of missing columns to descriptive dictionary
  metadataInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$missingCols_lst <- missingCols_lst_tmp
  # store list of additional, non-target columns to descriptive dictionary
  metadataInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$nontargetCols_dataset_lst <- nontargetCols_metadata_lst_tmp
}

##### harmonize datasets & metadata
####################################################################################################################
####################################################################################################################

### harmonize datasets
##########################################################

## Niger (2011)
##########

# rename variables to correspond to template
dataset_dct[['NER_2011_pd']] <- dataset_dct[['NER_2011_pd']] %>%
  rename(
    lon = long,
    harvest_month = harvesting_month,
    harvest_year = harvesting_year,
    dataset_name = source
  )

# overwrite GPS_level value: using harmonised naming convention
dataset_dct[['NER_2011_pd']]$GPS_level <- replace(dataset_dct[['NER_2011_pd']]$GPS_level, dataset_dct[['NER_2011_pd']]$GPS_level == 'Grappe', 3)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NER_2011_pd']]$adm3 <- NA
dataset_dct[['NER_2011_pd']]$adm4 <- NA
dataset_dct[['NER_2011_pd']]$harvest_month_begin <- NA
dataset_dct[['NER_2011_pd']]$harvest_year_begin <- NA
dataset_dct[['NER_2011_pd']]$harvest_month_end <- NA
dataset_dct[['NER_2011_pd']]$harvest_year_end <- NA

# drop redundant variables
dataset_dct[['NER_2011_pd']] <- dataset_dct[['NER_2011_pd']] %>%
  select(-grappe, -plotNbr, -cropID)

# preliminarily, set outstanding variables to NaN
dataset_dct[['NER_2011_pd']]$season <- NA

## Nigeria (2015)
##########

# drop redundant variables
dataset_dct[['NIG_2015_pd']] <- dataset_dct[['NIG_2015_pd']] %>%
  select(-wave, -dm_gender, -gps_meas)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NIG_2015_pd']]$fieldID <- NA

# set redundant variables to NaN
dataset_dct[['NIG_2015_pd']]$harvest_year <- NA
dataset_dct[['NIG_2015_pd']]$harvest_month <- NA

## Nigeria (2018)
##########

# rename variables to correspond to template
dataset_dct[['NIG_2018_pd']] <- dataset_dct[['NIG_2018_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude
  )

# drop redundant variables
dataset_dct[['NIG_2018_pd']] <- dataset_dct[['NIG_2018_pd']] %>%
  select(-wave, -dm_gender, -gps_meas)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NIG_2018_pd']]$fieldID <- NA

# set redundant variables to NaN
dataset_dct[['NIG_2018_pd']]$harvest_year <- NA
dataset_dct[['NIG_2018_pd']]$harvest_month <- NA

## Uganda (2011)
##########

# rename variables to correspond to template
dataset_dct[['UGA_2011_pd']] <- dataset_dct[['UGA_2011_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude,
    dataset_name = source
  )

# set variables genuinely missing in original dataset to NaN
dataset_dct[['UGA_2011_pd']]$fieldID <- NA

## Uganda (2013)
##########

# rename variables to correspond to template
dataset_dct[['UGA_2013_pd']] <- dataset_dct[['UGA_2013_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude,
    dataset_name = source
  )

# set variables genuinely missing in original dataset to NaN
dataset_dct[['UGA_2013_pd']]$fieldID <- NA

# correct variable name of fully missing variable to correspond to template
dataset_dct[['UGA_2013_pd']] <- dataset_dct[['UGA_2013_pd']] %>%
  rename(
    plot_area_measured_ha = plot_area_measured
  )

### harmonize metadata
##########################################################

## Niger (2011)
##########

# complete missing variable-name value (copying value from unnamed column that otherwise only contains duplicates)
metadata_dct[['NER_2011_pd']]$varName_harmonized[metadata_dct[['NER_2011_pd']]$varName_source == 'as02bq03'] <- 'plotNbr'

# drop redundant variables: unnamed columns
metadata_dct[['NER_2011_pd']] <- metadata_dct[['NER_2011_pd']] %>%
  select(-starts_with('Unnamed'))

# overwrite dataset_name
metadata_dct[['NER_2011_pd']]$dataset_name <- "NER_2011_ECVMA_v01_M"

# overwrite dataset_doi
metadata_dct[['NER_2011_pd']]$dataset_doi <- "https://doi.org/10.48529/bp16-s524"

# rename variables to correspond to template
metadata_dct[['NER_2011_pd']]$varName_harmonized <- recode(metadata_dct[['NER_2011_pd']]$varName_harmonized,
  'latitude' = 'lat',
  'longitude' = 'lon'
)

# drop redundant variable-values
metadata_dct[['NER_2011_pd']] <- metadata_dct[['NER_2011_pd']] %>%
  filter(varName_harmonized != 'plotNbr')

## Nigeria (2015)
##########

# set missing statistics-variable to NaN
metadata_dct[['NIG_2015_pd']]$pctMissing_harmonized <- NA
metadata_dct[['NIG_2015_pd']]$pctMissing_source <- NA

## Nigeria (2018)
##########

# set missing statistics-variable to NaN
metadata_dct[['NIG_2018_pd']]$pctMissing_harmonized <- NA
metadata_dct[['NIG_2018_pd']]$pctMissing_source <- NA

##### merge datasets & metadata
####################################################################################################################
####################################################################################################################

### merge datasets
##########################################################

# load all individual dataframes into single dataframe
allData_pd <- bind_rows(dataset_dct)

# drop rows that are NaN across all columns
allData_pd <- allData_pd %>%
  drop_na(everything())

# save to disk
write.csv(allData_pd, file.path(githubRepo_path, 'PostProcess', 'data_merged.csv'), row.names = FALSE)

### merge metadata
##########################################################

# load all individual metadata-files into single dataframe
allMetadata_pd <- bind_rows(metadata_dct)

# drop rows that are NaN across all columns
allMetadata_pd <- allMetadata_pd %>%
  drop_na(everything())

# save to disk
write.csv(allMetadata_pd, file.path(githubRepo_path, 'PostProcess', 'metadata_merged.csv'), row.names = FALSE)


