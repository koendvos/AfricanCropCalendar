rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(finalfit)
library(readr)


in.path.ppd <- "C:/Users/roetzeso/Documents/LSMS_multiplecropping/PostProcess/"
METADATA.file <- "metadata_merged.csv" 
METADATA.file <- read_csv(paste0(in.path.ppd, METADATA.file))

DATA.file <- "postprocessed_data.csv" 
DATA <- read_csv(paste0(in.path.ppd, DATA.file))


#correct the dataset_name
METADATA.file <- METADATA.file %>%
  mutate(dataset_name = case_when(
    dataset_name == "NGA_2018_GHSP-W4_v03" ~ "NGA_2018_GHSP-W4_v03_M",
    TRUE ~ dataset_name  # Keep other values unchanged
  ))

#correct some variable names
METADATA.file <- METADATA.file %>% 
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "latitude", "lat")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "longitude", "lon")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "plot_area_measured", "plot_area_measured_ha"))  %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "plot_area_measured_ha_ha", "plot_area_measured_ha"))  %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "harvesting_month", "harvest_month")) %>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "harvesting_year", "harvest_year"))%>%
  mutate (varName_harmonized = str_replace_all(varName_harmonized, "source", "dataset_name"))

#delete line with cropID
METADATA.file <- METADATA.file %>%
  filter(varName_harmonized != "cropID")%>%
  filter(varName_harmonized != "wave")

#calculate NA percentage
na_percentage <- DATA %>%
  group_by(dataset_name) %>%
  summarise(across(everything(), ~ sum(is.na(.)) / n() * 100, .names = "na_pct_{.col}")) %>%
  pivot_longer(cols = starts_with("na_pct_"), 
               names_to = "varName_harmonized", 
               values_to = "pctMissing") %>%
  mutate(varName_harmonized = gsub("na_pct_", "", varName_harmonized))

META <- full_join(METADATA.file,na_percentage, by = c("dataset_name", "varName_harmonized"))

#removing variables
variables_to_remove <- c("country", "harvest_month", "harvest_year")
META <- META %>% filter(!varName_harmonized %in% variables_to_remove)


META <- META %>% select(-pctMissing_source, -pctMissing_harmonized) #%>% rename(pctMissing = pctMissing_harmonized)

#add missing country, year and dataset_doi
META <- META %>%
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

#add missing rows
META <- META %>%
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

#adding missing labels
META <- META %>%
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


META <- META %>%
  select(where(~!all(is.na(.))))
write_csv(META, "PostProcess/postprocessed_metadata.csv")
