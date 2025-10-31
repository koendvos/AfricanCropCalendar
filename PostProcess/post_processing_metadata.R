#This script merges the individual country and survey metadata files, 
#inspects and cleans them to create a merged metadata file
#authors: Uwe Grewer (initially dataMerge.py, later translated to dataMerge.R),
#Sophie Rötzer and Katharina Waha
################################################################################

rm(list=ls(all=TRUE))
gc()

# Load libraries ----------------------------------------------------------
library(dplyr)
library(tidyverse)
library(haven)
library(finalfit)
library(readr)

# Define project folder path and set working directory to project  --------

in.path <- "C:/Users/wahakath/Documents/Research/multiple cropping/LSMS_multiplecropping"
setwd(in.path)

# Load dataset-------------------------------------------------

dat.file <- "/PostProcess/postprocessed_data.csv"
dat <- read_csv(paste0(in.path, dat.file))

# Load individual country/survey metadata files --------------

# directory containing final datasets 
outData_dir <- file.path(in.path, 'out')

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
metadata_template_pd <- read.csv(file.path(in.path, 'documentation/metadata_template/metadata_template.csv'))

# target columns list
targetCols_metadata_lst <- colnames(metadata_template_pd)

# Inspect metadata --------------------------------------------------------

# dictionary with descriptive information
metadataInspect_dct <- list()

# add keys to dictionary
for (key in names(metadata_dct)) {
  metadataInspect_dct[[substr(key, 1, nchar(key) - 3)]] <- list()
}

# inspect missing columns

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

# Harmonize metadata files (Niger, Nigeria) -----------------------------------

## Niger (2011)

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

# set missing statistics-variable to NaN
metadata_dct[['NIG_2015_pd']]$pctMissing_harmonized <- NA
metadata_dct[['NIG_2015_pd']]$pctMissing_source <- NA

## Nigeria (2018)

# set missing statistics-variable to NaN
metadata_dct[['NIG_2018_pd']]$pctMissing_harmonized <- NA
metadata_dct[['NIG_2018_pd']]$pctMissing_source <- NA

# correct variable data types
for (df_string in names(metadata_dct)) {
  metadata_dct[[df_string]]$year <- as.character(metadata_dct[[df_string]]$year)
}

# Merge metadata files ----------------------------------------------------

# load all individual metadata-files into single dataframe
allMetadata_pd <- bind_rows(metadata_dct)

# only keep rows with at least one non-NA value
allMetadata_pd <- allMetadata_pd %>% 
  filter_all(any_vars(!is.na(.)))

#-----------------------
# in.path.ppd <- "C:/Users/roetzeso/Documents/LSMS_multiplecropping/PostProcess/"
# METADATA.file <- "metadata_merged.csv" 
# METADATA.file <- read_csv(paste0(in.path.ppd, METADATA.file))
# #DATA.file <- "data_merged.csv" 
# dates_file <- "data_collection_dates.csv"
# #DATA <- read_csv(paste0(in.path.ppd, DATA.file))
# #METADATA.file <- read_csv(paste0(in.path.ppd, METADATA.file))
# data_collection_dates <- read_delim((paste0(in.path, "/PostProcess/", dates_file)), 
#                                     delim = ";")
# DATA.file <- "postprocessed_data.csv" 
# DATA <- read_csv(paste0(in.path.ppd, DATA.file))
#--------------------------------------------------------------

# Correct dataset_name ----------------------------------------------------

allMetadata_pd <- allMetadata_pd %>%
  mutate(dataset_name = case_when(
    dataset_name == "NGA_2018_GHSP-W4_v03" ~ "NGA_2018_GHSP-W4_v03_M",
    TRUE ~ dataset_name  # Keep other values unchanged
  ))

# Correct variable names --------------------------------------------------

allMetadata_pd <- allMetadata_pd %>% 
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "latitude", "lat")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "longitude", "lon")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "plot_area_measured", "plot_area_measured_ha"))  %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "plot_area_measured_ha_ha", "plot_area_measured_ha"))  %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "harvesting_month", "harvest_month")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "harvesting_year", "harvest_year")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "source", "dataset_name"))

# Remove additional variables ---------------------------------------------

allMetadata_pd <- allMetadata_pd %>%
  filter(varName_harmonized != "cropID") %>%
  filter(varName_harmonized != "wave") %>%
  filter(varName_harmonized != "season") %>%
  filter(varName_harmonized != "harvest_year") %>%
  filter(varName_harmonized != "harvest_month") %>%
  filter(varName_harmonized != "country") 

# Add missing country, year and dataset_doi -------------------------------

allMetadata_pd <- allMetadata_pd %>%
  mutate(
    #UGA 2011
    country = if_else(dataset_name == "UGA_2011_UNPS_v01_M", "Uganda", country),
    year = if_else(dataset_name == "UGA_2011_UNPS_v01_M", "2011-2012", year),
    dataset_doi = if_else(dataset_name == "UGA_2011_UNPS_v01_M", "https://doi.org/10.48529/5cpp-r373", dataset_doi),
    #UGA 2013
    country = if_else(dataset_name == "UGA_2013_UNPS_v02_M", "Uganda", country),
    year = if_else(dataset_name == "UGA_2013_UNPS_v02_M", "2013-2014", year),
    dataset_doi = if_else(dataset_name == "UGA_2013_UNPS_v02_M", "https://doi.org/10.48529/c1c4-h654", dataset_doi),
    # Nigeria 2018
    country = if_else(dataset_name == "NGA_2018_GHSP-W4_v03_M", "Nigeria", country),
    year = if_else(dataset_name == "NGA_2018_GHSP-W4_v03_M", "2018", year),
    dataset_doi = if_else(dataset_name == "NGA_2018_GHSP-W4_v03_M", "https://doi.org/10.48529/1hgw-dq47", dataset_doi),
    # Nigeria 2015
    country = if_else(dataset_name == "NGA_2015_GHSP-W3_v02_M", "Nigeria", country),
    year = if_else(dataset_name == "NGA_2015_GHSP-W3_v02_M", "2015", year),
    dataset_doi = if_else(dataset_name == "NGA_2015_GHSP-W3_v02_M", "https://doi.org/10.48529/7xmj-q133", dataset_doi),
    # Niger 2014
    country = if_else(dataset_name == "NER_2014_ECVMA-II_v02_M", "Niger", country),
    year = if_else(dataset_name == "NER_2014_ECVMA-II_v02_M", "2014-2015", year),
    dataset_doi = if_else(dataset_name == "NER_2014_ECVMA-II_v02_M", "https://doi.org/10.48529/3xnb-sd96", dataset_doi),
    # Mali 2017
    country = if_else(dataset_name == "MLI_2017_EAC-I_v03_M", "Mali", country),
    year = if_else(dataset_name == "MLI_2017_EAC-I_v03_M", "2017-2018", year),
    dataset_doi = if_else(dataset_name == "MLI_2017_EAC-I_v03_M", "https://doi.org/10.48529/0v50-h966", dataset_doi),
    # Mali 2014
    country = if_else(dataset_name == "MLI_2014_EACI_v03_M", "Mali", country),
    year = if_else(dataset_name == "MLI_2014_EACI_v03_M", "2014-2015", year),
    dataset_doi = if_else(dataset_name == "MLI_2014_EACI_v03_M", "https://doi.org/10.48529/qqam-mn86", dataset_doi),
    # Niger 2011
    country = if_else(dataset_name == "NER_2011_ECVMA_v01_M", "Niger", country),
    year = if_else(dataset_name == "NER_2011_ECVMA_v01_M", "2011-2012", year),
    dataset_doi = if_else(dataset_name == "NER_2011_ECVMA_v01_M", "https://doi.org/10.48529/bp16-s524", dataset_doi)
  )


# Add missing rows --------------------------------------------------------

allMetadata_pd <- allMetadata_pd %>%
  add_row(
    country = "Mali",
    year = "2014-15",
    dataset_name = "MLI_2014_EACI_v03_M",
    dataset_doi = "https://doi.org/10.48529/qqam-mn86"
  )%>%
  add_row(
    country = "Mali",
    year = "2017-18",
    dataset_name = "MLI_2017_EAC-I_v03_M ",
    dataset_doi = "https://doi.org/10.48529/0v50-h966"
  )%>%
  add_row(
    country = "Niger",
    year = "2014-15",
    dataset_name = "NER_2014_ECVMA-II_v02_M",
    dataset_doi = "https://doi.org/10.48529/3xnb-sd96"
  )


# Add missing labels ------------------------------------------------------

allMetadata_pd <- allMetadata_pd %>%
  mutate(
    varName_source = if_else(dataset_name == "UGA_2013_UNPS_v02_M" & varName_harmonized == "crop_area_share", "a4aq9", varName_source),
    varLabel_source = if_else(dataset_name == "UGA_2013_UNPS_v02_M" & varName_harmonized == "crop_area_share", "what percentage of the plot area was under this crop?", varLabel_source)
  ) %>%
  mutate(
    varLabel_source = if_else(dataset_name == "MWI_2010-2013_IHPS_v01_M" & varName_harmonized == "lon", "GPS Longitude Modified", varLabel_source),
    varLabel_source = if_else(dataset_name == "MWI_2010-2013_IHPS_v01_M" & varName_harmonized == "lat", "GPS Latitude Modified", varLabel_source)
  ) %>%
  mutate(
    varLabel_source = if_else(dataset_name == "NGA_2015_GHSP-W3_v02_M" & varName_harmonized == "crop_area_share", "WHAT WAS THE LAND AREA OF [CROP] HARVESTED? (PERCENT OF PLOT AREA)", varLabel_source)
  ) %>%
  mutate(
    varLabel_source = if_else(dataset_name == "NER_2011_ECVMA_v01_M" & varName_source == "as02bq08", "How much area was given to the cultivation of each crop?(square meters)", varLabel_source)
  ) %>%
  mutate(
    varLabel_source = if_else(dataset_name == "NER_2011_ECVMA_v01_M" & varName_harmonized == "crop_area_share", "Surface cultivée consacrée à chaque culture, Superficie de la parcelle GPS (en mètre carré)", varLabel_source)
  )

# Calculate percentage of NAs in harmonized variables ---------------------

na_percentage <- dat %>%
  group_by(dataset_name) %>%
  summarise(across(everything(), ~ sum(is.na(.)) / n() * 100, .names = "na_pct_{.col}")) %>%
  pivot_longer(cols = starts_with("na_pct_"), 
               names_to = "varName_harmonized", 
               values_to = "pctMissing") %>%
  mutate(varName_harmonized = gsub("na_pct_", "", varName_harmonized))

META <- full_join(allMetadata_pd, na_percentage, by = c("dataset_name", "varName_harmonized"))
META <- META %>% select(-pctMissing_harmonized, -pctMissing_source, 
                        -dataset_name, -dataset_doi, -X, -X.1, -X.2) 
META <- META %>%
  select(where(~!all(is.na(.))))

# Write output  -----------------------------------------------------------

write_csv(META, "PostProcess/postprocessed_metadata.csv")
