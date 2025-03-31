# Uganda 2015-2016
# Extract information about planting & harvest dates
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)


# Input files -------------------------------------------------------------
in.path.uga <- "UGA_2011_UNPS_v01_M_SPSS/"
plotroster.file <- "agsec2a.csv" #SECTION 2A: CURRENT LAND HOLDINGS- SECOND/FIRST VISIT
planting_first.file <- "agesec4a.csv" #SECTION 4A: CROPS GROWN AND TYPES OF SEEDS USED - FIRST VISIT 
planting_second.file <- "AGSEC4B.csv" #SECTION 4B: CROPS GROWN AND TYPE OF SEEDS USED - SECOND VISIT 
harvesting_first.file <- "AGSEC5A.csv" #SECTION 5A: QUANTIFICATION OF PRODUCTION- FIRST VISIT
harvesting_second.file <- "AGSEC5B.csv" #SECTION 5B: QUANTIFICATION OF PRODUCTION- SECOND VISIT
householdidentification.file <- "GSEC1.csv" #Household Identification Particulars
crop.code <- 'Crop_Code.csv'
geovar <-"UNPS_Geovars_1112.csv"

#file UGA_HouseholdGeovariables_Y3 contains HH GPS coordinates

# Read input and select variables -----------------------------------------
crop_code <- read_csv(paste0(in.path.uga, crop.code)) %>%
  set_names(c('crop', 'crop_code'))

#parcel information - keep for now in case parcel area measured should be included
#a <- read_csv(paste0(in.path.uga, plotroster.file))
#a <- a %>% select(HHID, parcelID, a2aq4, a2aq5) %>%
#  set_names(c("hhID", "parcelID", "plot_area_measured_localUnit", "plot_area_reported_localUnit")) 
#  mutate(parcel_area_measured = parcel_area_measured / 2.471) %>% #acres to hectares
#  mutate(parcel_area_reported = parcel_area_reported / 2.471) %>% #acres to hectares
#  mutate(country = 'Uganda')


g <- read_csv(paste0(in.path.uga, geovar))
g <- g %>% select(HHID, lat_mod, lon_mod, source) %>%
  set_names(c("hhID", "latitude", "longitude", "GPS_level")) 


b <- read_csv(paste0(in.path.uga, householdidentification.file))
b <- b %>% select(HHID, h1aq1, h1aq2, h1aq3, h1aq4) %>%
  set_names(c("hhID", "adm1", "adm2", "adm3", "adm4"))

b<-inner_join(b,g,by=c("hhID"))

c <- read_csv(paste0(in.path.uga, planting_first.file))
c <- c %>% select(HHID, plotID, cropID,  
                  a4aq7, a4aq9, Crop_Planted_Month, Crop_Planted_Year,a4aq8) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year","crop_stand")) %>%
 # mutate(plot_area_reported = plot_area_reported / 2.471) %>% #acres to hectares 
  mutate(planting_year = planting_year + 2000) %>%
  filter(planting_month %in% c(1:12))

c$localUnit_area<-"acres"
c$plot_area_reported_ha<-c$plot_area_reported_localUnit/2.471
c$plot_area_measured_ha<-NA

c <- inner_join(c, crop_code, by = c('cropID' = 'crop_code'))
c$crop_area_share[(is.na(c$crop_area_share)) & (c$crop_stand=="Pure Stand")]=100 #fill NA is crop_area_share if pure stand
c <- subset(c, select = -c(crop_stand))

d <- read_csv(paste0(in.path.uga, harvesting_first.file))
d <- d %>% select(HHID, plotID, cropID, 
                  a5aq6e, a5aq6f) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
               "harvest_month_end")) %>%
  filter(harvest_month_begin %in% c(1:12)) %>%
  filter(harvest_month_end %in% c(1:12))

d$harvest_year_begin=NA 
d$harvest_year_end=NA 

d <- inner_join(d, crop_code, by = c('cropID' = 'crop_code'))

e <- read_csv(paste0(in.path.uga, planting_second.file))
e <- e %>% select(HHID, plotID, cropID,  
                  a4bq7, a4bq9, Crop_Planted_Month2, Crop_Planted_Year2,a4bq8) %>%
  set_names(c("hhID", "plotID", "cropID", "plot_area_reported_localUnit",
              "crop_area_share", "planting_month", "planting_year","crop_stand")) %>%
  #mutate(plot_area_reported = plot_area_reported * (if_else(is.na(crop_perc), 1, crop_perc/100)), .keep='unused') %>%
  filter(planting_month %in% c(1:12)) %>% 
  mutate(planting_year = planting_year + 2000)

e$localUnit_area<-"acres"
e$plot_area_reported_ha<-e$plot_area_reported_localUnit/2.471
e$plot_area_measured_ha<-NA

e$crop_area_share[is.na(e$crop_area_share) & (e$crop_stand==1)]=100 #fill NA is crop_area_share if pure stand
e <- inner_join(e, crop_code, by = c('cropID' = 'crop_code'))

e <- subset(e, select = -c(crop_stand))

f <- read_csv(paste0(in.path.uga, harvesting_second.file))
f <- f %>% select(HHID, plotID, cropID, 
                  a5bq6e, a5bq6f) %>%
  set_names(c("hhID", "plotID", "cropID", "harvest_month_begin", 
              "harvest_month_end")) %>%
  filter(harvest_month_begin %in% c(1:12)) %>%
  filter(harvest_month_end %in% c(1:12))

f$harvest_year_begin=NA 
f$harvest_year_end=NA 

f <- inner_join(f, crop_code, by = c('cropID' = 'crop_code'))

# Main --------------------------------------------------------------------

# Create data.frame for first visit ---------------------------------------------
plant_harvest_first <- full_join(c, d, by=c("hhID", "plotID", "crop"))
plant_harvest_first <- plant_harvest_first %>%
  mutate(season = "first") %>% 
  select(!c(cropID.x,cropID.y)) #remove crop ID as crop name is now included



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
plant_harvest$harvest_month <- NA
plant_harvest$harvest_year <- NA

#add survey ID and country
plant_harvest$dataset_name <- "UGA_2011_UNPS_v01_M"
plant_harvest$dataset_doi <- "https://doi.org/10.48529/5cpp-r373"
plant_harvest$country <- "Uganda"



#missing values
plant_harvest_na <- plant_harvest %>% summarise_all(funs(100*mean(is.na(.))))

ce<-bind_rows(c,e)
c_na <- ce %>% summarise_all(funs(100*mean(is.na(.))))

df<-bind_rows(d,f)
d_na <- df %>% summarise_all(funs(100*mean(is.na(.))))

# Write output table ------------------------------------------------------
write_csv(plant_harvest, "out/uganda11-12.csv")


