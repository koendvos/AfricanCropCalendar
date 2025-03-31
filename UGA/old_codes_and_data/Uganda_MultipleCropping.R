# Uganda 2015-2016
# Extract information about planting & harvest dates
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)

# 2015/16 Agriculture Questionnaire
# Two visits, first visit for season Jun-Dec 2014 and second visit for season Jan-Jun 2015)

# Input files -------------------------------------------------------------
in.path.uga <- "Z:/LSMS/Uganda/LSMS_2015-16_Uganda/UGA_2015_UNPS_v02_M_CSV/UGA_2015_UNPS_v02_M_CSV/"
plotroster.file <- "agsec2a.csv" #SECTION 2A: CURRENT LAND HOLDINGS- SECOND/FIRST VISIT
planting_first.file <- "agsec4a.csv" #SECTION 4A: CROPS GROWN AND TYPES OF SEEDS USED - FIRST VISIT 
planting_second.file <- "agsec4b.csv" #SECTION 4B: CROPS GROWN AND TYPE OF SEEDS USED - SECOND VISIT 
harvesting_first.file <- "agsec5a.csv" #SECTION 5A: QUANTIFICATION OF PRODUCTION- FIRST VISIT
harvesting_second.file <- "agsec5b.csv" #SECTION 5B: QUANTIFICATION OF PRODUCTION- SECOND VISIT
householdidentification.file <- "gsec1.csv" #Household Identification Particulars
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
b <- b %>% select(HHID, district_name, subcounty_name, parish_name, village_name) %>%
  set_names(c("hhID", "adm1", "adm2", "adm3", "adm4"))

c <- read_csv(paste0(in.path.uga, planting_first.file))
c <- c %>% select(HHID, plotID, cropID,  
                  a4aq7, a4aq9, a4aq9_1, a4aq9_2) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported",
              "crop_area_share", "planting_month", "planting_year")) %>%
  mutate(plot_area_reported = plot_area_reported / 2.471) %>% #acres to hectares 
  mutate(planting_year = planting_year + 2000) %>%
  #mutate(plot_area_reported = plot_area_reported * (if_else(is.na(crop_perc), 1, crop_perc/100)), .keep='unused') %>%
  filter(planting_month %in% c(1:12)) 
c <- inner_join(c, crop_code, by = c('cropID' = 'crop_code'))

d <- read_csv(paste0(in.path.uga, harvesting_first.file))
d <- d %>% select(HHID, plotID, cropID, 
                  a5aq6e, a5aq6e_1, a5aq6f, a5aq6f_1) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end")) %>%
  filter(harvest_month_begin %in% c(1:12)) %>%
  filter(harvest_month_end %in% c(1:12)) %>%
  filter(harvest_year_begin %in% c(2001:2015)) %>%
  filter(harvest_year_end %in% c(2001:2015))
d <- inner_join(d, crop_code, by = c('cropID' = 'crop_code'))

e <- read_csv(paste0(in.path.uga, planting_second.file))
e <- e %>% select(HHID, plotID, cropID,  
                  a4bq7, a4bq9, a4bq9_1, a4bq9_2) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported",
              "crop_area_share", "planting_month", "planting_year")) %>%
  mutate(plot_area_reported = plot_area_reported / 2.471) %>% #acres to hectares 
  #mutate(plot_area_reported = plot_area_reported * (if_else(is.na(crop_perc), 1, crop_perc/100)), .keep='unused') %>%
  filter(planting_month %in% c(1:12)) %>% 
  mutate(planting_year = planting_year + 2000)
e <- inner_join(e, crop_code, by = c('cropID' = 'crop_code'))

f <- read_csv(paste0(in.path.uga, harvesting_second.file))
f <- f %>% select(HHID, plotID, cropID, 
                  a5bq6e, a5bq6e_1, a5bq6f, a5bq6f_1) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_year_begin", "harvest_month_end", "harvest_year_end")) %>%
  filter(harvest_month_begin %in% c(1:12)) %>%
  filter(harvest_month_end %in% c(1:12)) %>%
  filter(harvest_year_begin %in% c(2001:2015)) %>%
  filter(harvest_year_end %in% c(2001:2015))
f <- inner_join(f, crop_code, by = c('cropID' = 'crop_code'))

# Main --------------------------------------------------------------------

# Create data.frame for first visit ---------------------------------------------
plant_harvest_first <- full_join(c, d, by=c("hhID", "plotID", "crop"))
plant_harvest_first <- plant_harvest_first %>%
  mutate(season = "first") %>% 
  select(!c(cropID.x, cropID.y)) #remove crop ID as crop name is now included

# Create data.frame for second visit ---------------------------------------------
plant_harvest_second <- full_join(e, f, by=c("hhID", "plotID", "crop"))
plant_harvest_second <- plant_harvest_second %>%
  mutate(season = "second") %>% 
  select(!c(cropID.x, cropID.y)) #remove crop ID as crop name is now included

#join
plant_harvest <- bind_rows(plant_harvest_first, plant_harvest_second)
plant_harvest <- plant_harvest %>%
  arrange(hhID)
plant_harvest <- merge(plant_harvest, b, by = "hhID", all.x = TRUE)

#add harmonized variables not available
plant_harvest$latitude <- NA
plant_harvest$longitude <- NA
plant_harvest$GPS_level <- NA
plant_harvest$plot_area_measured <- NA #only parcel area was measured
plant_harvest$harvest_month <- NA
plant_harvest$harvest_year <- NA

#add survey ID and country
plant_harvest$source <- "UGA_2015_UNPS_v02_M"
plant_harvest$country <- "Uganda"

#missing values
plant_harvest_na <- plant_harvest %>% summarise_all(funs(100*mean(is.na(.))))

# Write output table ------------------------------------------------------
write_csv(plant_harvest, "out/uganda.csv")


