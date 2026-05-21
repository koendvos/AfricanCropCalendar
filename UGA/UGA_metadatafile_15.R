# library(dplyr)
# library(tidyverse)
# library(haven)

metadata <- data.frame(matrix(ncol = 10, nrow = 28))
c_names <- c("country", "year", "varName_harmonized", "varName_source", "varLabel_source", "pctMissing_harmonized", "pctMissing_source", "comment", "dataset_name", "dataset_doi")
colnames(metadata) <- c_names
metadata$country <- "Uganda"
metadata$year <- "2015-16"
metadata$varName_harmonized <- colnames(plant_harvest)
metadata$dataset_name <- "UGA_2015_UNPS_v02_M"
metadata$dataset_doi <- "https://doi.org/10.48529/hm2z-2k12"

metadata$varName_harmonized

#Varname_source
metadata$varName_source=c(
  "HHID", #"hhID",
  "plotID", #"plotID",
  "a4aq7, a4bq7", #"plot_area_reported_localUnit",
  "a4aq9, a4bq9", #"crop_area_share",
  "a4aq9_1, a4bq9_1", #"planting_month",
  "a4aq9_2, a4bq9_2", #"planting_year",
  "parcelID", #"fieldID",
  NA, #plot_area_reported_ha",
  NA, #"localUnit_area",
  "cropID", #"crop",
  "a5aq6e, a5bq6e", #"harvest_month_begin",
  "a5aq6e_1, a5bq6e_1", #"harvest_year_begin",
  "a5aq6f, a5bq6f", #"harvest_month_end",
  "a5aq6f_1, a5bq6f_1", #"harvest_year_end",
  NA, #"season",
  "district_name", #"adm1",
  "subcounty_name", #"adm2",
  "parish_name", #"adm3",
  "village_name", #"adm4",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#VarLabel_source
metadata$varLabel_source=c(
  "Household number", #"hhID",
  "Plot identifier", #"plotID",
  "total area of plot planted", #"plot_area_reported_localUnit",
  "what percentage of the plot area was under this crop?, approximately what percentage of the plot area was under this crop?", #"crop_area_share",
  "Month crop planted", #"planting_month",
  "Year crop planted ", #"planting_year",
  "Parcel identifier", #"fieldID",
  NA, #plot_area_reported_ha",
  NA, #"localUnit_area",
  "Crop name, Crop_code2:crop name", #"crop",
  "in what month did the harvest begin?", #"harvest_month_begin",
  "in what year did the harvest begin?", #"harvest_year_begin",
  "in what month did the harvest end?", #"harvest_month_end",
  "in what year did the harvest end?", #"harvest_year_end",
  NA, #"season",
  "L1name ", #"adm1",
  "L2name ", #"adm2",
  "L3name", #"adm3",
  "L4name", #"adm4",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#pct_harmonized
trans_ph_na= t(plant_harvest_na)
metadata$pctMissing_harmonized <- c(trans_ph_na)


#pct source


zb <- read_csv(paste0(in.path.uga, householdidentification.file))
zb <- zb %>% select(HHID, district_name, subcounty_name, parish_name, village_name) %>%
  set_names(c("hhID", "adm1", "adm2", "adm3", "adm4"))

zc <- read_csv(paste0(in.path.uga, planting_first.file))
zc <- zc %>% select(HHID, plotID, cropID,  
                    a4aq7, a4aq9, a4aq9_1, a4aq9_2, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year", "fieldID")) 

zd <- read_csv(paste0(in.path.uga, harvesting_first.file))
zd <- zd %>% select(HHID, plotID, cropID, 
                    a5aq6e, a5aq6e_1, a5aq6f, a5aq6f_1, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end", "fieldID")) 

ze <- read_csv(paste0(in.path.uga, planting_second.file))
ze <- ze %>% select(HHID, plotID, cropID,  
                    a4bq7, a4bq9, a4bq9_1, a4bq9_2, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year", "fieldID"))

zf <- read_csv(paste0(in.path.uga, harvesting_second.file))
zf <- zf %>% select(HHID, plotID, cropID, 
                    a5bq6e, a5bq6e_1, a5bq6f, a5bq6f_1, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end", "fieldID"))

# #missing values
zce <- rbind(zc, ze)
zdf <- rbind(zd, zf)

# z_all <- merge(zb, zce, by = "hhID", all.x = TRUE, all.y = TRUE)

m_zb= zb %>% summarise_all(funs(100*mean(is.na(.))))
m_zce= zce %>% summarise_all(funs(100*mean(is.na(.))))
m_zdf= zdf %>% summarise_all(funs(100*mean(is.na(.))))

metadata$pctMissing_source=c(
  as.numeric(0), #"hhID",
  NA, #"plotID",
  as.numeric(m_zce[1,4]), #"plot_area_reported_localUnit",
  as.numeric(m_zce[1,5]), #"crop_area_share",
  as.numeric(m_zce[1,6]), #"planting_month",
  as.numeric(m_zce[1,7]), #"planting_year",
  as.numeric(0), #"fieldID",
  NA, #plot_area_reported_ha",
  NA, #"localUnit_area",
  NA, #"crop",
  as.numeric(m_zdf[1,4]), #"harvest_month_begin",
  as.numeric(m_zdf[1,5]), #"harvest_year_begin",
  as.numeric(m_zdf[1,6]), #"harvest_month_end",
  as.numeric(m_zdf[1,7]), #"harvest_year_end",
  NA, #"season",
  as.numeric(0), #"adm1",
  as.numeric(0), #"adm2",
  as.numeric(0), #"adm3",
  as.numeric(0), #"adm4",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#comments [,8]
metadata$comment=c(
  NA, #"hhID",
  "plotID may not be unique, not all rows in the original dataset are unique", #"plotID",
  "sometimes 0.000", #"plot_area_reported_localUnit",
  NA, #"crop_area_share",
  "Values recorded as 99, which were used for the answer >>Don't know<< to the question in which month the crop was planted in the source data, were converted to missing values", #"planting_month",
  NA, #"planting_year",
  NA, #"fieldID",
  NA, #"plot_area_reported_ha",
  "acres, according to The Uganda National Panel Survey 2015/16: Agriculture & Livestock Questionnaire", #"localUnit_area",
  NA, #"crop",
  "up to month 26", #"harvest_month_begin",
  "year 216 included", #"harvest_year_begin",
  "up to month 26", #"harvest_month_end",
  NA, #"harvest_year_end",
  "two visits approximately six months apart based on the two cropping seasons", #"season",
  NA, #"adm1",
  NA, #"adm2",
  NA, #"adm3",
  NA, #"adm4",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

write_csv(metadata, "out/UGA_2015-16_metadata.csv")

##############
#template for comments

# metadata$comment=c(
#   "hhID",
#   "plotID",
#   "plot_area_reported_localUnit",
#   "crop_area_share",
#   "planting_month",
#   "planting_year",
#   "plot_area_reported_ha",
#   "crop",
#   "harvest_month_begin",
#   "harvest_year_begin",
#   "harvest_month_end",
#   "harvest_year_end",
#   "season",
#   "adm1",
#   "adm2",
#   "adm3",
#   "adm4",
#   "lat",
#   "lon",
#   "GPS_level",
#   "plot_area_measured",
#   "harvest_month",
#   "harvest_year",
#   "fieldID",
#   "localUnit_area",
#   "dataset_name",
#   "country",
#   "dataset_doi"
# )
# 
# 
