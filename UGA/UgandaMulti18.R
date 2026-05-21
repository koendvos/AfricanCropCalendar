# Uganda 2018-2019
# Extract information about planting & harvest dates
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)

# 2018/19 Agriculture Questionnaire
# similar to 2015/16 there are two seasons

# Input files -------------------------------------------------------------
# in.path.uga <- "L:/Data/LSMS/Uganda/LSMS_2015-16_Uganda/UGA_2015_UNPS_v02_M_CSV/UGA_2015_UNPS_v02_M_CSV/"
# plotroster.file <- "AGSEC2A.csv" #SECTION 2A: CURRENT LAND HOLDINGS- SECOND/FIRST VISIT
# planting_first.file <- "AGSEC4A.csv" #SECTION 4A: CROPS GROWN AND TYPES OF SEEDS USED - FIRST VISIT 
# planting_second.file <- "AGSEC4B.csv" #SECTION 4B: CROPS GROWN AND TYPE OF SEEDS USED - SECOND VISIT 
# harvesting_first.file <- "AGSEC5A.csv" #SECTION 5A: QUANTIFICATION OF PRODUCTION- FIRST VISIT
# harvesting_second.file <- "AGSEC5B.csv" #SECTION 5B: QUANTIFICATION OF PRODUCTION- SECOND VISIT
# householdidentification.file <- "GSEC1.csv" #Household Identification Particulars
# crop.code <- 'Crop_Code.csv'

# Input files -------------------------------------------------------------
in.path.uga <- "L:/Data/LSMS/Uganda/LSMS_2018-19_Uganda/UGA_2018_UNPS_v02_M_CSV/UGA_2018_UNPS_v02_M_CSV/"
plotroster.file <- "AGSEC2A.csv" #SECTION 2A: CURRENT LAND HOLDINGS- SECOND/FIRST VISIT
planting_first.file <- "AGSEC4A.csv" #SECTION 4A: CROPS GROWN AND TYPES OF SEEDS USED - FIRST VISIT
planting_second.file <- "AGSEC4B.csv" #SECTION 4B: CROPS GROWN AND TYPE OF SEEDS USED - SECOND VISIT
harvesting_first.file <- "AGSEC5A.csv" #SECTION 5A: QUANTIFICATION OF PRODUCTION- FIRST VISIT
harvesting_second.file <- "AGSEC5B.csv" #SECTION 5B: QUANTIFICATION OF PRODUCTION- SECOND VISIT
householdidentification.file <- "GSEC1.csv" #Household Identification Particulars
crop.code <- 'Crop_Code.csv'

#file UGA_HouseholdGeovariables_Y3 contains HH GPS coordinates

# Read input and select variables -----------------------------------------
crop_code <- read_csv(paste0(in.path.uga, crop.code)) %>%
  set_names(c('crop', 'crop_code'))

#parcel information - keep for now in case parcel area measured should be included
#a <- read_csv(paste0(in.path.uga, plotroster.file))
#a <- a %>% select(HHID, parcelID, a2aq4, a2aq5) %>%
#  set_names(c("hhID", "parcelID", "parcel_area_measured", "parcel_area_reported")) %>% 
#  mutate(parcel_area_measured = parcel_area_measured / 2.471) %>% #acres to hectares
#  mutate(parcel_area_reported = parcel_area_reported / 2.471) %>% #acres to hectares
#  mutate(country = 'Uganda')

b <- read_csv(paste0(in.path.uga, householdidentification.file))
b <- b %>% select(hhid, district_2018, subcounty_2018, parish_2018, village) %>%
  set_names(c("hhID", "adm1", "adm2", "adm3", "adm4"))

c <- read_csv(paste0(in.path.uga, planting_first.file))
c <- c %>% select(hhid, pltid, cropID,  
                  s4aq07, s4aq09, s4aq09_1, s4aq09_2, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year", "fieldID")) %>%
  mutate(plot_area_reported_ha = plot_area_reported_localUnit / 2.471) %>% #acres to hectares 
  mutate(localUnit_area = case_when(plot_area_reported_localUnit >= 0 ~ "acres",
                                    is.na(plot_area_reported_localUnit)== TRUE ~ NA)) #%>%
  #mutate(planting_year = planting_year + 2000) #%>%
  #mutate(localUnit_area = if_else(is.na(plot_area_reported_localUnit), "NA", "acres"), .keep = "used") #%>% #doesn't work yet
  #mutate(plot_area_reported = plot_area_reported * (if_else(is.na(crop_perc), 1, crop_perc/100)), .keep='unused') %>%
  #filter(planting_month %in% c(1:12)) 
c <- inner_join(c, crop_code, by = c('cropID' = 'crop_code'))

d <- read_csv(paste0(in.path.uga, harvesting_first.file))
d <- d %>% select(hhid, pltid, cropID, 
                  s5aq06e_1, s5aq06e_1_1, s5aq06f_1, s5aq06f_1_1, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end", "fieldID")) #%>%
  # filter(harvest_month_begin %in% c(1:12)) %>%
  # filter(harvest_month_end %in% c(1:12)) %>%
  # filter(harvest_year_begin %in% c(2001:2015)) %>%
  # filter(harvest_year_end %in% c(2001:2015))
d <- inner_join(d, crop_code, by = c('cropID' = 'crop_code'))

e <- read_csv(paste0(in.path.uga, planting_second.file))
e <- e %>% select(hhid, pltid, cropID,  
                  s4bq07, s4bq09, s4bq09_1, s4bq09_2, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year", "fieldID")) %>%
  mutate(plot_area_reported_ha = plot_area_reported_localUnit / 2.471) %>% #acres to hectares 
  mutate(localUnit_area = case_when(plot_area_reported_localUnit >= 0 ~ "acres",
                                    is.na(plot_area_reported_localUnit)== TRUE ~ NA)) #%>%
  #mutate(plot_area_reported = plot_area_reported * (if_else(is.na(crop_perc), 1, crop_perc/100)), .keep='unused') %>%
  #filter(planting_month %in% c(1:12)) %>% 
  #mutate(planting_year = planting_year + 2000)
e <- inner_join(e, crop_code, by = c('cropID' = 'crop_code'))

f <- read_csv(paste0(in.path.uga, harvesting_second.file))
f <- f %>% select(hhid, pltid, cropID, 
                  s5bq06e_1, s5bq06e_1_1, s5bq06f_1, s5bq06f_1_1, parcelID) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end", "fieldID"))# %>%
  # filter(harvest_month_begin %in% c(1:12)) %>%
  # filter(harvest_month_end %in% c(1:12)) %>%
  # filter(harvest_year_begin %in% c(2001:2015)) %>%
  # filter(harvest_year_end %in% c(2001:2015))
f <- inner_join(f, crop_code, by = c('cropID' = 'crop_code'))

# Main --------------------------------------------------------------------

# Create data.frame for first visit ---------------------------------------------
plant_harvest_first <- full_join(c, d, by=c("hhID", "plotID", "crop", "fieldID"))
plant_harvest_first <- plant_harvest_first %>%
  mutate(season = "first") %>% 
  select(!c(cropID.x, cropID.y)) #remove crop ID as crop name is now included

# Create data.frame for second visit ---------------------------------------------
plant_harvest_second <- full_join(e, f, by=c("hhID", "plotID", "crop", "fieldID"))
plant_harvest_second <- plant_harvest_second %>%
  mutate(season = "second") %>% 
  select(!c(cropID.x, cropID.y)) #remove crop ID as crop name is now included

#join
plant_harvest <- bind_rows(plant_harvest_first, plant_harvest_second)
plant_harvest <- plant_harvest %>%
  arrange(hhID)
plant_harvest <- merge(plant_harvest, b, by = "hhID", all.x = TRUE)

#add harmonized variables not available
plant_harvest$lat <- NA
plant_harvest$lon <- NA
plant_harvest$GPS_level <- NA
plant_harvest$plot_area_measured_ha <- NA #only parcel area was measured
plant_harvest$harvest_month <- NA
plant_harvest$harvest_year <- NA
# plant_harvest$fieldID <- NA
# plant_harvest$localUnit_area <- NA #actually it's acres

#add survey ID, doi and country
plant_harvest$dataset_name <- "UGA_2018_UNPS_v02_M"
plant_harvest$country <- "Uganda"
plant_harvest$dataset_doi <- "https://doi.org/10.48529/ttyg-m774"


#missing values
plant_harvest_na <- plant_harvest %>% summarise_all(funs(100*mean(is.na(.))))

# Write output table ------------------------------------------------------
write_csv(plant_harvest, "out/UGA_2018-19.csv")


