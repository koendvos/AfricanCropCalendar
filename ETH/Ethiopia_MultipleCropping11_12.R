# Ethiopia 2011-2012
# Extract information about planting & harvest dates
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

# 2011-12 

# Input files -------------------------------------------------------------
in.path.eth <- "L:/Data/LSMS/Ethiopia/LSMS_2011-2012_Ethiopia/Data/ETH_2011_ERSS_v02_M_CSV/"
harvesting.file <- "sect9_ph_w1.csv" 
planting.file <- "sect4_pp_w1.csv" 
field.file <- "sect3_pp_w1.csv" #Field roster
parcel.file <- "sect10_hh_w1.csv" #Land Parcel roster, unsused
householdidentification.file <- "sect_cover_hh_w1.csv" #Household Identification Particulars
geovariables.file <- "Pub_ETH_HouseholdGeovariables_Y1.csv" #Household GPS coordinates
conversion.file <- "et_local_area_unit_conversion.csv" #Woreda and Zone code

# Read input and select variables -----------------------------------------

#read conversion file
#zone and woreda IDS are not unique but only unique within a region
conv <- read_csv(paste0(in.path.eth, conversion.file))
conv <- conv %>% select(region, zonename, zone, woredaname, woreda) %>%
  set_names(c("regionid", "adm2", "zoneid", "adm3", "woredaid")) %>%
  mutate(woredaid = paste(regionid, zoneid, woredaid, sep = "_")) %>%
  mutate(zoneid = paste(regionid, zoneid, sep = "_")) %>%
  distinct(adm3, .keep_all = TRUE) %>%
  mutate(adm1 = case_when(regionid == 1 ~ "Tigray",
                          regionid == 3 ~ "Amhara",
                          regionid == 4 ~ "Oromia",
                          regionid == 5 ~ "Somali",
                          regionid == 6 ~ "Benishangul Gumuz",
                          regionid == 7 ~ "SNNP",
                          regionid == 12 ~ "Gambela",
                          regionid == 13 ~ "Harar",
                          regionid == 15 ~ "Dire Dawa"))  #Region names from WorldBank microdata catalogue
regioncode <- conv %>% select(adm1, regionid) %>%
  add_row(adm1 = "Addis Ababa", regionid = 14) %>%
  add_row(adm1 = "Afar", regionid = 2) %>%
  distinct(adm1, .keep_all = TRUE)
zonecode <- conv %>% select(adm2, zoneid) %>%
  distinct(adm2, .keep_all = TRUE)
woredacode <- conv %>% select(adm3, woredaid) %>%
  distinct(adm3, .keep_all = TRUE)

#read household identification file
b <- read_csv(paste0(in.path.eth, householdidentification.file))
b <- b %>% select(household_id, saq01, saq02, saq03) %>%
  set_names(c("hhID", "regionid", "zoneid", "woredaid")) %>% 
  mutate(zoneid = as.numeric(zoneid),
         woredaid = as.numeric(woredaid)) %>%
  distinct(hhID, .keep_all = TRUE) %>%
  mutate(woredaid = paste(regionid, zoneid, woredaid, sep = "_")) %>%
  mutate(zoneid = paste(regionid, zoneid, sep = "_")) 
b <- left_join(b, regioncode, by = "regionid") #, unmatched = 'error'
b <- left_join(b, zonecode, by = "zoneid", multiple = "first") 
b <- left_join(b, woredacode, by = "woredaid") 
b <- b %>% distinct(hhID, .keep_all = TRUE) 


#Planting
# month.name.eth <- c(month.name, "Pagume")
c <- read_csv(paste0(in.path.eth, planting.file))
c <- c %>% select(household_id, parcel_id, field_id, 
                  crop_name, pp_s4q03, pp_s4q12_a, pp_s4q12_b, crop_code, pp_saq07) %>%
  set_names(c("hhID", "fieldID", "plotID", 
              "crop","crop_area_share", "planting_month", "planting_year", "crop_id", "holder_id")) 

c <- c %>%
  # separate(planting_month, c(NA, "planting_month"), sep=". ") %>%
  # mutate(planting_month = str_replace(planting_month, "Pwagume", "Pagume")) %>% #the 13th month in Ethiopian calendar
  # mutate(planting_month = match(planting_month, month.name.eth)) %>%
  # separate(crop, c(NA, "crop"), sep=". ", extra = "merge") %>%
  mutate(across(crop, tolower)) %>%
  mutate(crop = case_when(crop == "mengibin/ masho" ~ "mung bean/ masho", TRUE ~ crop)) %>%
  #mutate(plotID = paste(parcelID, fieldID, sep = "_")) %>%
  mutate(join_ID = paste(plotID, fieldID, crop, holder_id, sep = "_")) %>%
  mutate(join_2nd = paste(plotID, fieldID, holder_id, sep = "_")) #%>%
  # mutate(crop = ifelse(crop_id == 72, "coffee", crop)) %>%
  #select(!c(parcelID, fieldID))


#Harvest
d <- read_csv(paste0(in.path.eth, harvesting.file))
d <- d %>% select(household_id, parcel_id, field_id, crop_name,
                  ph_s9q13_a, ph_s9q13_b, crop_code, ph_saq07) %>%
  set_names(c("hhID", "fieldID", "plotID", "crop",
              "harvest_month_begin", "harvest_month_end", "crop_id", "holder_id")) 

d <- d %>%
  # separate(harvest_month_begin, c(NA, "harvest_month_begin"), sep=". ") %>%
  # mutate(harvest_month_begin = str_replace(harvest_month_begin, "Pwagume", "Pagume")) %>% #the 13th month in Ethiopian calendar
  # mutate(harvest_month_begin = match(harvest_month_begin, month.name.eth)) %>%
  # separate(harvest_month_end, c(NA, "harvest_month_end"), sep=". ") %>%
  # mutate(harvest_month_end = str_replace(harvest_month_end, "Pwagume", "Pagume")) %>% #the 13th month in Ethiopian calendar
  # mutate(harvest_month_end = match(harvest_month_end, month.name.eth)) %>%
  # separate(crop, c(NA, "crop"), sep=". ", extra = "merge") %>%
  mutate(across(crop, tolower)) %>%
  mutate(crop = case_when(crop == "mengibin/ masho" ~ "mung bean/ masho", TRUE ~ crop)) %>%
  #mutate(plotID = paste(parcelID, fieldID, sep = "_")) %>%#
  mutate(join_ID = paste(plotID, fieldID, crop, holder_id, sep = "_")) #%>%
  #select(!c(parcelID, fieldID))

#Household coordinates
e <- read_csv(paste0(in.path.eth, geovariables.file))
e <- e %>% select(household_id, LAT_DD_MOD, LON_DD_MOD) %>%
  set_names(c("hhID", "lat", "lon")) %>%
  mutate(GPS_level = case_when(lat >= 0 ~ 3,
                                 is.na(lat)== TRUE ~ NA))


#Field area reported and measured
f <- read_csv(paste0(in.path.eth, field.file))
f <- f %>% select(household_id, parcel_id, field_id, 
                  pp_s3q02_d, pp_s3q02_c, pp_s3q05_c, pp_saq07) %>%
  set_names(c("hhID", "fieldID", "plotID",  
              "plot_area_reported_localUnit", "localUnit_area", "plot_area_measured_ha", "holder_id")) 

f <- f %>%
  mutate(plot_area_reported_ha = case_when(localUnit_area == 2 ~ plot_area_reported_localUnit / 10000, #sqm to hectares
                                        localUnit_area == 1 ~ plot_area_reported_localUnit,
                                        localUnit_area == 3 ~ plot_area_reported_localUnit / 4, #timad to hectares
                                        TRUE ~ as.numeric(NA))) %>% #everything else is NA 
  mutate(plot_area_measured_ha = plot_area_measured_ha / 10000) %>% #sqm to hectares 
  #mutate(plotID = paste(parcel_ID, field_ID, sep = "_")) %>%
  mutate(join_2nd = paste(plotID, fieldID, holder_id, sep = "_")) %>%
  #mutate(join_ID = paste(parcelID, fieldID, crop, holder_id, sep = "_")) %>%
  select(!c(holder_id))

# Main --------------------------------------------------------------------

# Create data.frame for planting and harvesting ---------------------------------------------
plant_harvest <- full_join(c, d, by=c("hhID", "plotID", "join_ID", "fieldID"))#, relationship = "many-to-many")
plant_harvest <- subset(plant_harvest, select=-c(crop_id.x, crop_id.y, holder_id.x, holder_id.y, crop.y))
colnames(plant_harvest)[4]="crop"


#add b, e and f
#only add adm unit and GPS information for rows with data in plant_harvest - same as merge(...all.x=TRUE)
plant_harvest <- left_join(plant_harvest, b, by = "hhID") 
plant_harvest <- left_join(plant_harvest, e, by = "hhID")
plant_harvest <- left_join(plant_harvest, f, by = c("hhID", "plotID", "join_2nd", "fieldID")) #unmatched= "error",
plant_harvest <- subset(plant_harvest, select=-c(join_ID, join_2nd))



# #add harmonized variables not available
plant_harvest$season <- NA
plant_harvest$harvest_month <- NA
plant_harvest$harvest_year <- NA
plant_harvest$harvest_year_begin <- NA
plant_harvest$harvest_year_end <- NA
plant_harvest$adm4 <- NA
#plant_harvest$fieldID <- NA
# plant_harvest$GPS_level <- NA # in case GPS_level has to be set to NA again


#add survey ID and country
plant_harvest$dataset_name <- "ETH_2011_ERSS_v02_M" #the online version changed to v03_M ??
plant_harvest$country <- "Ethiopia"
plant_harvest$dataset_doi <- "https://doi.org/10.48529/80xt-9m68"

#remove unnecessary variables and missing values
plant_harvest <- plant_harvest %>% select(!c(zoneid, woredaid, regionid))
plant_harvest_na <- plant_harvest %>% summarise_all(funs(100*mean(is.na(.))))

# Write output table ------------------------------------------------------
write_csv(plant_harvest, "out/ETH_2011-12.csv")


