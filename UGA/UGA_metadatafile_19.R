# library(dplyr)
# library(tidyverse)
# library(haven)

metadata <- data.frame(matrix(ncol = 10, nrow = 28))
c_names <- c("country", "year", "varName_harmonized", "varName_source", "varLabel_source", "pctMissing_harmonized", "pctMissing_source", "comment", "dataset_name", "dataset_doi")
colnames(metadata) <- c_names
metadata$country <- "Uganda"
metadata$year <- "2019-20"
metadata$varName_harmonized <- colnames(plant_harvest)
metadata$dataset_name <- "UGA_2019_UNPS_v03_M"
metadata$dataset_doi <- "https://doi.org/10.48529/nqzx-f196"

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
  "district", #"adm1",
  "s1aq03a", #"adm2",
  "s1aq04a", #"adm3",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"adm4",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#VarLabel_source
metadata$varLabel_source=c(
  "Unique household identifier in 2019/20/ Unique 32-character long identifier of the interview", #"hhID",
  "Plot identifier", #"plotID",
  "7.What was the total area of %rostertitle% planted?", #"plot_area_reported_localUnit",
  "9. Approximately what percentage of the plot area was under this %rostertitle%?", #"crop_area_share",
  "9.1. What month was the crop planted?", #"planting_month",
  "9.2. What year was the crop planted?(YYYY)", #"planting_year",
  "Parcel identifier", #"fieldID",
  NA, #plot_area_reported_ha",
  NA, #"localUnit_area",
  "Id in crop_code", #"crop",
  "6e. Month harvest began (2018, full harvest, condition1)", #"harvest_month_begin",
  "6e1. Year harvest began (2018, full harvest, condition1)", #"harvest_year_begin",
  "6f. Month harvest ended (2018, full harvest, condition1)", #"harvest_month_end",
  "6f1. Year harvest ended (2018, full harvest, condition1)", #"harvest_year_end",
  NA, #"season",
  "District Name", #"adm1",
  "3. Sub-County/Division/Town Council", #"adm2",
  "4. Parish/Ward", #"adm3",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"adm4",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#pct_harmonized
trans_ph_na= t(plant_harvest_na)
metadata$pctMissing_harmonized <- c(trans_ph_na)


#pct source


zb <- read_csv(paste0(in.path.uga, householdidentification.file))
zb <- zb %>% select(hhid, district, s1aq03a, s1aq04a) %>%
  set_names(c("hhID", "adm1", "adm2", "adm3"))

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
  as.numeric(0), #"crop",
  as.numeric(m_zdf[1,4]), #"harvest_month_begin",
  as.numeric(m_zdf[1,5]), #"harvest_year_begin",
  as.numeric(m_zdf[1,6]), #"harvest_month_end",
  as.numeric(m_zdf[1,7]), #"harvest_year_end",
  NA, #"season",
  as.numeric(m_zb[1,2]), #"adm1",
  as.numeric(m_zb[1,3]), #"adm2",
  as.numeric(m_zb[1,4]), #"adm3",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"adm4",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#comments [,8]
metadata$comment=c(
  "hhid was changed again since 2018/19, the old ones are available in the raw data", #"hhID",
  "may not be unique", #"plotID",
  NA, #"plot_area_reported_localUnit",
  NA, #"crop_area_share",
  NA, #"planting_month",
  "value 9998 for planting year", #"planting_year",
  NA, #"fieldID",
  NA, #"plot_area_reported_ha",
  "according to The Uganda National Panel Survey 2019/20 Agriculture Questionnaire", #"localUnit_area",
  NA, #"crop",
  NA, #"harvest_month_begin",
  "range 20 to 2819", #"harvest_year_begin",
  NA, #"harvest_month_end",
  "range 24 to 2819", #"harvest_year_end",
  "two visits approximately six months apart based on the two cropping seasons", #"season",
  NA, #"adm1",
  NA, #"adm2",
  NA, #"adm3",
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_measured",
  NA, #"harvest_month",
  NA, #"harvest_year",
  "no village name", #"adm4",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

write_csv(metadata, "out/UGA_2019-20_metadata.csv")

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
