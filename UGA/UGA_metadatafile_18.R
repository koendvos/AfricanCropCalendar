# library(dplyr)
# library(tidyverse)
# library(haven)

metadata <- data.frame(matrix(ncol = 10, nrow = 28))
c_names <- c("country", "year", "varName_harmonized", "varName_source", "varLabel_source", "pctMissing_harmonized", "pctMissing_source", "comment", "dataset_name", "dataset_doi")
colnames(metadata) <- c_names
metadata$country <- "Uganda"
metadata$year <- "2018-19"
metadata$varName_harmonized <- colnames(plant_harvest)
metadata$dataset_name <- "UGA_2018_UNPS_v02_M"
metadata$dataset_doi <- "https://doi.org/10.48529/ttyg-m774"

metadata$varName_harmonized

#Varname_source
metadata$varName_source=c(
  "hhid", #"hhID",
  "pltid", #"plotID",
  "s4aq07, s4bq07", #"plot_area_reported_localUnit",
  "s4aq09, s4bq09", #"crop_area_share",
  "s4aq09_1, s4bq09_1", #"planting_month",
  "s4aq09_2, s4bq09_2", #"planting_year",
  "parcelID", #"fieldID",
  NA, #plot_area_reported_ha",
  NA, #"localUnit_area",
  "cropID", #"crop",
  "s5aq06e_1, s5bq06e_1", #"harvest_month_begin",
  "s5aq06e_1_1, s5bq06e_1_1", #"harvest_year_begin",
  "s5aq06f_1, s5bq06f_1", #"harvest_month_end",
  "s5aq06f_1_1, s5bq06f_1_1", #"harvest_year_end",
  NA, #"season",
  "district_2018/ distirct_name", #"adm1",
  "subcounty_2018/ subcounty_name", #"adm2",
  "parish_2018/ parish_name", #"adm3",
  "village/ ???", #"adm4",
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
  "Unique household identifier in 2018/19/ InterviewId", #"hhID",
  "Plot identifier", #"plotID",
  "7.What was the total area of %rostertitle% planted?", #"plot_area_reported_localUnit",
  "9. Approximately what percentage of the plot area was under this %rostertitle%?", #"crop_area_share",
  "9.1. What month was the crop planted?", #"planting_month",
  "9.2. What year was the crop planted?(YYYY)", #"planting_year",
  "Parcel identifier", #"fieldID",
  NA, #plot_area_reported_ha",
  NA, #"localUnit_area",
  "Roster instance identifier", #"crop",
  "6e. In what month did the harvest begin?", #"harvest_month_begin",
  "6e_1. In what year did the harvest begin? (YY)", #"harvest_year_begin",
  "6f. In what month did the harvest end?,", #"harvest_month_end",
  "6f_1. In what year did the harvest end? (YY)", #"harvest_year_end",
  NA, #"season",
  "District name", #"adm1",
  "Sub country name", #"adm2",
  "Parish Code", #"adm3",
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

#pct_harmonized
trans_ph_na= t(plant_harvest_na)
metadata$pctMissing_harmonized <- c(trans_ph_na)


#pct source


zb <- read_csv(paste0(in.path.uga, householdidentification.file))
zb <- zb %>% select(hhid, district_2018, subcounty_2018, parish_2018, village) %>%
  set_names(c("hhID", "adm1", "adm2", "adm3", "adm4"))

zc <- read_csv(paste0(in.path.uga, planting_first.file))
zc <- zc %>% select(hhid, pltid, cropID,  
                    s4aq07, s4aq09, s4aq09_1, s4aq09_2, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year", "fieldID")) 

zd <- read_csv(paste0(in.path.uga, harvesting_first.file))
zd <- zd %>% select(hhid, pltid, cropID, 
                    s5aq06e_1, s5aq06e_1_1, s5aq06f_1, s5aq06f_1_1, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end", "fieldID")) 

ze <- read_csv(paste0(in.path.uga, planting_second.file))
ze <- ze %>% select(hhid, pltid, cropID,  
                    s4bq07, s4bq09, s4bq09_1, s4bq09_2, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year", "fieldID"))

zf <- read_csv(paste0(in.path.uga, harvesting_second.file))
zf <- zf %>% select(hhid, pltid, cropID, 
                    s5bq06e_1, s5bq06e_1_1, s5bq06f_1, s5bq06f_1_1, parcelID) %>%
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
  as.numeric(0), #"plotID",
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
  "hhid was changed since 2016, both are available in the raw data", #"hhID",
  "plotID may not be unique", #"plotID",
  "sometimes 0.00", #"plot_area_reported_localUnit",
  NA, #"crop_area_share",
  NA, #"planting_month",
  "range: 2 to 20186", #"planting_year",
  NA, #"fieldID",
  NA, #"plot_area_reported_ha",
  "according to the Uganda National Panel Survey 2018-2019, Agriculture Questionnaire ", #"localUnit_area",
  NA, #"crop",
  NA, #"harvest_month_begin",
  "range: 0 to 20186", #"harvest_year_begin",
  NA, #"harvest_month_end",
  "range: 201 to 2818", #"harvest_year_end",
  "two visits approximately six months apart based on the two cropping seasons", #"season",
  "different label in study documentation and .csv file", #"adm1",
  "different label in study documentation and .csv file", #"adm2",
  "different label in study documentation and .csv file", #"adm3",
  "label non existent in study documentary", #"adm4",
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

write_csv(metadata, "out/UGA_2018-19_metadata.csv")

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
