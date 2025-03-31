# Niger 2014-2015
# Extract information about planting & harvest dates
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

# Input files -------------------------------------------------------------
in.path.ner <- paste0(dirname(dirname(rstudioapi::getSourceEditorContext()$path)),"/")
data.path.ner <- paste0(in.path.ner,"data/")
harvesting.file <- "ECVMA2_AS2E1P2.csv" #
planting.file <- "ECVMA2_AS2BP1.csv" #
householdidentification.file <- "ECVMA2_MS00P1.csv" #Household Identification Particulars
geovariables.file <- "eaci_geovariables_2017.csv" #Household GPS coordinates
conversion.file <- "adm_conversion.csv" #Woreda and Zone code
area.file <- "ECVMA2_AS1P2.csv" #information on parcel area

# Read input and select variables -----------------------------------------
#Had to create crop.code file

commune_grappe_code <- read_table(paste0(data.path.ner,"rawData/commune_grappe_code.txt"),col_names = FALSE) %>%
  mutate(commune_code = as.numeric(paste0(X5,X6))) %>%
  rename(adm3 = X7)

reg_file = read_xlsx(paste0(data.path.ner,"ner_grappe_code.xlsx"))
geo_file = read_dta(paste0(data.path.ner,"NER_EA_Offsets.dta")) %>%
  rename(GRAPPE = grappe)

b <- read_csv(paste0(data.path.ner, householdidentification.file)) %>%
  mutate(hhID = paste(GRAPPE,MENAGE,sep="_")) %>%
  left_join(geo_file,by="GRAPPE") %>%
  rename(region = MS00Q10) %>%
  rename(department = MS00Q11) %>%
  rename(commune = MS00Q12) %>%
  rename(commune_code = commune)%>%
  left_join(reg_file %>% select(region,adm1),by="region") %>%
  left_join(reg_file %>% select(region,adm2) %>% rename(department = region),by="department") %>%
  left_join(commune_grappe_code %>% select(adm3,commune_code),by="commune_code") %>%
  select(hhID,adm1,adm2,adm3,commune_code,LAT_DD_MOD,LON_DD_MOD)



#zone and woreda IDS are not unique but only unique within a region

crop_code = read_delim(paste0(data.path.ner,"crop_conversion.csv"), 
                       delim = ";", escape_double = FALSE, trim_ws = TRUE)

 c <- read_csv(paste0(data.path.ner, planting.file)) %>%
   mutate(hhID = paste(GRAPPE,MENAGE,sep="_")) %>%
   rename(fieldID = AS01Q01,
          plotID = AS01Q03,
          crop_area = AS02BQ08,
          planting_month = AS02BQ11,
          crop_code = AS02BQ06) %>%
   left_join(crop_code,by="crop_code") %>%
   select(hhID,fieldID,plotID,planting_month,crop,crop_area)
 
 plotArea = c %>%
   group_by(hhID,fieldID,plotID) %>%
   summarize(totarea = sum(crop_area,na.rm=T))
 
 c = c %>%
   left_join(plotArea,by=c('hhID','fieldID','plotID')) %>%
   mutate(crop_area_share = crop_area/totarea*100)
 c$crop_area_share[is.nan(c$crop_area_share)]=NA
 c = c %>%
   mutate(plot_area_reported = crop_area/10000) %>%
   mutate(planting_year = NA) %>%
   select(hhID,fieldID,plotID,planting_month,planting_year,crop,crop_area,crop_area_share,plot_area_reported)
 
 ca = read_csv(paste0(data.path.ner,area.file)) %>%
   mutate(hhID = paste(GRAPPE,MENAGE,sep='_')) %>%
   rename(fieldID = AS01Q01,
          plotID = AS01Q03) %>%
   mutate(plot_area_measured = AS01Q07/10000) %>%
   select(hhID,fieldID,plotID,plot_area_measured)
 
 c = c %>%
   left_join(ca,by=c("hhID","fieldID","plotID"))
 c$crop_area_share[c$crop_area_share==0]=NA
 
 plotArea_meas = c %>%
   filter(is.na(crop_area_share)) %>%
   filter(plot_area_measured > 0) %>%
   group_by(hhID,fieldID,plotID) %>%
   summarize(totArea_m = sum(plot_area_measured))
 
 c = c %>%
   left_join(plotArea_meas,by=c("hhID","fieldID","plotID")) %>%
   mutate(crop_area_share = ifelse(is.na(crop_area_share),plot_area_measured/totArea_m*100,crop_area_share)) %>%
   select(-crop_area,-totArea_m)
 
 h = read_csv(paste0(data.path.ner,harvesting.file)) %>%
   mutate(hhID = paste(GRAPPE,MENAGE,sep='_')) %>%
   rename(fieldID = AS02EQ01,
          plotID = AS02EQ03,
          rainyseason = AS02EQ04,
          crop_code = CULTURE,
          harvest_month_begin = AS02EQ06A,
          harvest_month_end = AS02EQ06B) %>%
   left_join(crop_code,by="crop_code") %>%
   mutate(season = ifelse(rainyseason == 1,'Rainy Season',NA)) %>%
   mutate(harvest_month_begin = ifelse(harvest_month_begin %in% seq(1,12),harvest_month_begin,NA),
          harvest_month_end = ifelse(harvest_month_end %in% seq(1,12), harvest_month_end,NA)) %>%
   #mutate(harvest_year_begin = ifelse(harvest_month_begin >=6,2014,2015),
      #    harvest_year_end = ifelse(harvest_month_end >=6,2014,2015)) %>%
   #mutate(harvest_month = as.integer((harvest_month_begin+harvest_month_end)/2)) %>%
   #mutate(harvest_year = as.integer((harvest_year_begin+harvest_year_end)/2)) %>%
   mutate(harvest_year_begin = NA) %>%
   mutate(harvest_year_end = NA) %>%
   mutate(harvest_month = NA) %>%
   mutate(harvest_year = NA) %>%
   select(hhID,fieldID,plotID,season,crop,harvest_month_begin,harvest_month_end,harvest_month,harvest_year_begin,harvest_year_end,harvest_year)

file = c %>%
  left_join(h,by=c("hhID","fieldID","plotID","crop"))%>%
  left_join(b,by="hhID") %>%
  mutate(lat = as.numeric(LAT_DD_MOD),
         lon = as.numeric(LON_DD_MOD),
         GPS_level = 3,
         country = "Niger",
         adm4 = NA,
         source = "NER_2014_ECVMA-II_v02_M")%>%
  rename(plot_area_reported_ha = plot_area_reported,
         plot_area_measured_ha = plot_area_measured) %>%
  mutate(dataset_name = "NER_2014_ECVMA-II_v02_M",
         dataset_doi = "https://doi.org/10.48529/3xnb-sd96",
         plot_area_reported_localUnit = NA,
         localUnit_area = NA) %>%
  select(hhID,lat,lon,GPS_level,country,adm1,adm2,adm3,adm4,fieldID,plotID,crop,season,plot_area_reported_ha,plot_area_measured_ha,crop_area_share,planting_month,harvest_month,harvest_month_begin,
         harvest_month_end,planting_year,harvest_year,harvest_year_begin,harvest_year_end,dataset_name,dataset_doi,
         plot_area_reported_localUnit,localUnit_area)

# # Write output table ------------------------------------------------------
write_csv(file, paste0(in.path.ner,"/out/NER_2014-15.csv"))
