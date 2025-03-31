# Ethiopia 2018-2019
# Extract information about planting & harvest dates
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

# 2018-19 

# Input files -------------------------------------------------------------
in.path.eth <- "L:/Data/LSMS/Ethiopia/LSMS_2018-2019_Ethiopia/Data/ETH_2018_ESS_v02_M_CSV/"
harvesting.file <- "sect9_ph_w4.csv" 
planting.file <- "sect4_pp_w4.csv" 
field.file <- "sect3_pp_w4.csv" #Field roster
parcel.file <- "sect10b_hh_w4.csv" #Land Parcel roster
householdidentification.file <- "sect_cover_hh_w4.csv" #Household Identification Particulars
geovariables.file <- "ETH_HouseholdGeovariables_Y4.csv" #Household GPS coordinates
conversion.file <- "ET_local_area_unit_conversion.csv" #Woreda and Zone code

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
b <- left_join(b, regioncode, by = "regionid", unmatched = 'error') 
b <- left_join(b, zonecode, by = "zoneid", multiple = "first") 
b <- left_join(b, woredacode, by = "woredaid") 
b <- b %>% distinct(hhID, .keep_all = TRUE) 
# counting missing values in source
b %>% summarise_all(funs(100*mean(is.na(.))))

#Planting
month.name.eth <- c(month.name, "Pagume")
c <- read_csv(paste0(in.path.eth, planting.file))
c <- c %>% select(household_id, parcel_id, field_id, 
                  s4q01b, s4q03, s4q13a, s4q13b) %>%
  set_names(c("hhID", "parcelID", "fieldID", "crop",
              "crop_area_share", "planting_month", "planting_year")) 
# counting missing values in source
c %>% summarise_all(funs(100*mean(is.na(.))))
c <- c %>%
  separate(planting_month, c(NA, "planting_month"), sep=". ") %>%
  mutate(planting_month = str_replace(planting_month, "Pwagume", "Pagume")) %>% #the 13th month in Ethiopian calendar
  mutate(planting_month = match(planting_month, month.name.eth)) %>%
  separate(crop, c(NA, "crop"), sep=". ", extra = "merge") %>%
  mutate(across(crop, tolower)) %>%
  mutate(plotID = paste(parcelID, fieldID, sep = "_")) %>%
  select(!c(parcelID, fieldID))
#month count starts from September which should be September 2018 but the year is given as 2010 or 2011?
#make sure consistent with harvest year!

#Harvest
d <- read_csv(paste0(in.path.eth, harvesting.file))
d <- d %>% select(household_id, parcel_id, field_id, s9q00b,
                  s9q08a, s9q08b) %>%
  set_names(c("hhID", "parcelID", "fieldID", "crop",
              "harvest_month_begin", "harvest_month_end")) 
# counting missing values in source
d %>% summarise_all(funs(100*mean(is.na(.))))
d <- d %>%
  separate(harvest_month_begin, c(NA, "harvest_month_begin"), sep=". ") %>%
  mutate(harvest_month_begin = str_replace(harvest_month_begin, "Pwagume", "Pagume")) %>% #the 13th month in Ethiopian calendar
  mutate(harvest_month_begin = match(harvest_month_begin, month.name.eth)) %>%
  separate(harvest_month_end, c(NA, "harvest_month_end"), sep=". ") %>%
  mutate(harvest_month_end = str_replace(harvest_month_end, "Pwagume", "Pagume")) %>% #the 13th month in Ethiopian calendar
  mutate(harvest_month_end = match(harvest_month_end, month.name.eth)) %>%
  separate(crop, c(NA, "crop"), sep=". ", extra = "merge") %>%
  mutate(across(crop, tolower)) %>%
  mutate(plotID = paste(parcelID, fieldID, sep = "_")) %>%
  select(!c(parcelID, fieldID))

#Household coordinates
e <- read_csv(paste0(in.path.eth, geovariables.file))
e <- e %>% select(household_id, lat_mod, lon_mod) %>%
  set_names(c("hhID", "latitude", "longitude"))
# counting missing values in source
e %>% summarise_all(funs(100*mean(is.na(.))))

#Field area reported and measured
f <- read_csv(paste0(in.path.eth, field.file))
f <- f %>% select(household_id, parcel_id, field_id, s3q02a, s3q02b, s3q08) %>%
  set_names(c("hhID", "parcel_ID", "field_ID", 
              "plot_area_reported", "plot_area_reported_unit", "plot_area_measured")) 
# counting missing values in source
f %>% summarise_all(funs(100*mean(is.na(.))))
f <- f %>%
  mutate(plot_area_reported = case_when(plot_area_reported_unit == "2. Square Meters" ~ plot_area_reported / 10000, #sqm to hectares
                                        plot_area_reported_unit == "1. Hectare" ~ plot_area_reported,
                                        plot_area_reported_unit == "3. Timad" ~ plot_area_reported / 4, #timad to hectares
                                        TRUE ~ as.numeric(NA))) %>% #everything else is NA 
  mutate(plot_area_measured = plot_area_measured / 10000) %>% #sqm to hectares 
  mutate(plotID = paste(parcel_ID, field_ID, sep = "_")) %>%
  select(!c(parcel_ID, field_ID))

# Main --------------------------------------------------------------------

# Create data.frame for planting and harvesting ---------------------------------------------
plant_harvest <- full_join(c, d, by=c("hhID", "plotID", "crop"), relationship = "many-to-many")

#add b, e and f
#only add adm unit and GPS information for rows with data in plant_harvest - same as merge(...all.x=TRUE)
plant_harvest <- left_join(plant_harvest, b, by = "hhID") 
plant_harvest <- left_join(plant_harvest, e, by = "hhID")
plant_harvest <- left_join(plant_harvest, f, by = c("hhID", "plotID"))

# #add harmonized variables not available
plant_harvest$season <- NA
plant_harvest$harvest_month <- NA
plant_harvest$harvest_year <- NA
plant_harvest$harvest_year_begin <- NA
plant_harvest$harvest_year_end <- NA

#add survey ID and country
plant_harvest$source <- "ETH_2018_ESS_v02_M" #the online version changed to v03_M ??
plant_harvest$country <- "Ethiopia"

#remove unnecessary variables and missing values
plant_harvest <- plant_harvest %>% select(!c(zoneid, woredaid, regionid))
plant_harvest_na <- plant_harvest %>% summarise_all(funs(100*mean(is.na(.))))

# Write output table ------------------------------------------------------
write_csv(plant_harvest, "out/ethiopia_forcomparison.csv")


