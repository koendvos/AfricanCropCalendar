# Mali - Koen De Vos
# Extract information about planting & harvest dates
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

#Wave1: 2014-2015

# Input files -------------------------------------------------------------
path.mli <- paste0(dirname(dirname(rstudioapi::getSourceEditorContext()$path)),"/")
crop.file <- "mli_crop_code.xlsx" #Mali crop codes
data.mli = paste0(path.mli,"data/")

# Read input and dplyr::select variables -----------------------------------------
#Had to create crop.code file
crop_code <- read_excel(paste0(data.mli,crop.file), sheet = "Sheet1") %>%
  set_names(c('crop_code', "crop"))

# Functions
add_Admin = function(basefile,adminfile,admin_level){
  
  basefilex = basefile %>%
    subset(select=c("hhID",paste0("adm",admin_level),"grappe")) %>%
    set_names(c("hhID","adm","grappe"))
  
  adminfile = adminfile %>%
    set_names(c("adm","adm_name"))
  
  file = basefilex %>%
    left_join(adminfile,by=c('adm')) %>%
    dplyr::select(hhID,adm_name,grappe) %>%
    set_names(c("hhID",paste0("adm",admin_level),"grappe"))
  
  basefile = basefile %>%
    dplyr::select(-paste0('adm',admin_level)) %>%
    left_join(file,by="hhID")
  return(file)
}


##Wave 1: 2014-2015
harvesting.file <- "eacis3a_p2.csv" #
planting.file <- "eaciculture_p1.csv" #
householdidentification.file <- "eaciexploi_p1.csv" #Household Identification Particulars
geovariables.file <- "eaci_geovariables_2014.csv" #Household GPS coordinates
area.file <- "eaciexploi_p1.csv" #information on parcel area
conversion.file <- "adm_conversion_2014.csv" #Woreda and Zone code


#Collecting Admin Information
y <- read_delim(paste0(data.mli,conversion.file), 
                delim = ";", escape_double = FALSE, trim_ws = TRUE) %>%
  distinct() 
adm1 = y %>%
  filter(Adm_Level == 1) %>%
  rename(adm1 = Value,
         adm1_name = Category) %>%
  dplyr::select(adm1,adm1_name)
adm2 = y %>%
  filter(Adm_Level == 2) %>%
  rename(adm2 = Value,
         adm2_name = Category) %>%
  dplyr::select(adm2,adm2_name)
adm3 = y %>%
  filter(Adm_Level == 3) %>%
  rename(adm3 = Value,
         adm3_name = Category) %>%
  dplyr::select(adm3,adm3_name)


#Collecting Household Information
b <- read_csv(paste0(data.mli, householdidentification.file))
b <- b %>%
  mutate(hhID = paste(grappe,menage,sep="_")) %>%
  rename(adm1 = s0aq01,
         adm2 = s0aq02,
         adm3 = s0aq03) %>%
  mutate(adm4 = NA) %>%
  dplyr::select(hhID,adm1,adm2,adm3,adm4,grappe) %>%
  mutate(adm2 = as.numeric(paste0(adm1,adm2))) %>%
  mutate(adm3 = as.numeric(paste0(adm2,adm3)))

#Joining Household with Admin
bx = b %>%
  left_join(adm1,by="adm1") %>%
  left_join(adm2,by="adm2") %>%
  left_join(adm3,by="adm3") %>%
  dplyr::select(hhID,adm1_name,adm2_name,adm3_name,grappe) %>%
  rename(adm1 = adm1_name,
         adm2 = adm2_name,
         adm3 = adm3_name)


#Collecting Cropping information
c <- read_csv(paste0(data.mli, planting.file)) %>%
  mutate(hhID = paste(grappe,menage,sep="_"))%>%
  rename(fieldID = s1cq01,
         plotID = s1cq02,
         crop_code = s1cq03,
         crop_area_share = s1cq06,
         planting_month = s1cq11b)%>%
  left_join(crop_code,by="crop_code") %>%
  dplyr::select(hhID,fieldID,plotID,crop,crop_area_share,planting_month)%>%
  filter(planting_month %in% seq(1,12))

#Collecting Plot Area information
ca <- read_csv(paste0(data.mli,area.file)) %>%
  mutate(hhID = paste(grappe,menage,sep="_"))%>%
  rename(fieldID = s1bq01,
         plotID = s1bq02,
         plot_area_measured = s1bq05a,
         plot_area_reported = s1bq10)%>%
  dplyr::select(hhID,fieldID,plotID,plot_area_measured,plot_area_reported)
ca[ca == Inf]=NA

#Joining cropping information with plot information
c = c %>%
  left_join(ca,by=c("hhID","fieldID","plotID")) %>%
  mutate(season = NA) %>%
  mutate(source = "MLI_2014_EACI_v03_M") %>%
  mutate(country = "Mali")

#Collecting harvesting information
h <- read.csv(paste0(data.mli,harvesting.file)) %>%
  mutate(hhID = paste(grappe,menage,sep="_")) %>%
  rename(fieldID = s3aq01,
         plotID = s3aq02,
         harvest_month_begin = s3aq04b,
         harvest_month_end = s3aq07b) %>%
  mutate(harvest_year_begin = NA,
         harvest_year_end = NA)
h[h==Inf]=NA
h[h==99]=NA
#h=h %>%
#  mutate(harvest_year_begin = ifelse(is.na(harvest_year_begin) & harvest_month_begin >6,2014,
#                                     ifelse(is.na(harvest_year_begin) & harvest_month_begin <=6,2015,harvest_year_begin))) %>%
#  mutate(harvest_year_end = ifelse(is.na(harvest_year_end),harvest_year_begin,harvest_year_end))
#h$harvest_month = as.integer((h$harvest_month_begin+h$harvest_month_end)/2)
#h$harvest_year = as.integer((h$harvest_year_begin+h$harvest_year_end)/2)
#h$harvest_month[is.na(h$harvest_month) & is.na(h$harvest_month_end)]=h$harvest_month_begin[is.na(h$harvest_month) & is.na(h$harvest_month_end)]
#h$harvest_month[is.na(h$harvest_month) & is.na(h$harvest_month_begin)]=h$harvest_month_end[is.na(h$harvest_month) & is.na(h$harvest_month_begin)]
h$harvest_month = NA
h$harvest_year = NA

h = h %>%
  dplyr::select(hhID,fieldID,plotID,harvest_month,harvest_year,harvest_month_begin,harvest_month_end,harvest_year_begin,harvest_year_end)


#Loading GeoVariables to link with households/Admin Level
geo = read.csv(paste0(data.mli,geovariables.file)) %>%
  rename(lat = lat_dd_mod,
         lon = lon_dd_mod) %>%
  mutate(GPS_level = 3) %>%
  dplyr::select(grappe,lat,lon,GPS_level)

#Joining Files by hhID, fieldID, and plotID
file = c %>%
  left_join(h,by=c("hhID","fieldID","plotID")) %>%
  left_join(bx,by=c("hhID")) %>%
  left_join(geo,by="grappe") %>%
  distinct() %>%
  mutate(adm4 = NA,
         season = NA) %>%
  mutate(country = "Mali") %>%
  rename(plot_area_measured_ha = plot_area_measured,
         plot_area_reported_ha = plot_area_reported) %>%
  mutate(plot_area_reported_localUnit = NA,
         localUnit_area = NA) %>%
  mutate(dataset_name = "MLI_2014_EACI_v03_M") %>%
  mutate(dataset_doi = "https://doi.org/10.48529/qqam-mn86") %>%
  mutate(planting_year = ifelse(planting_month > harvest_month,harvest_year-1,harvest_year)) %>%
  dplyr::select(country,adm1,adm2,adm3,adm4,lat,lon,GPS_level,hhID,fieldID,plotID,crop,season,plot_area_measured_ha,
         plot_area_reported_ha,plot_area_reported_localUnit,localUnit_area,crop_area_share,planting_year,planting_month,harvest_month,
         harvest_year,harvest_month_begin,harvest_month_end,harvest_year_begin,harvest_year_end,dataset_name,dataset_doi)

wave1 = file

##Wave 2: 2017-2018
harvesting.file <- "eaci17_s7fp2.csv" #
planting.file <- "eaci17_s11cp1.csv" #
householdidentification.file <- "eaci17_s00p1.csv" #Household Identification Particulars
geovariables.file <- "eaci_geovariables_2017.csv" #Household GPS coordinates
conversion.file <- "adm_conversion.csv" #Woreda and Zone code
area.file <- "eaci17_s11bp1.csv" #information on parcel area

y <- read_delim(paste0(data.mli,conversion.file), 
                delim = ";", escape_double = FALSE, trim_ws = TRUE) %>%
  distinct() %>%
  dplyr::select(Value,Category) %>%
  rename(zone_name = Category)

b <- read_csv(paste0(data.mli, householdidentification.file))
b <- b %>%
  mutate(hhID = paste(grappe,exploitation,sep="_")) %>%
  rename(adm1 = s0q01,
         adm2 = s0q02,
         adm3 = s0q03) %>%
  mutate(adm4 = NA) %>%
  dplyr::select(hhID,adm1,adm2,adm3,adm4,grappe)

bx = lapply(seq(1,3), function(level) add_Admin(b,y,level)) %>%
  plyr::join_all(by=c("hhID","grappe"))
#zone and woreda IDS are not unique but only unique within a region

 c <- read_csv(paste0(data.mli, planting.file)) %>%
   mutate(hhID = paste(grappe,exploitation,sep="_")) %>%
   rename(fieldID = s11cq01,
          plotID = s11cq02,
          crop_code = s11cq03,
          crop_area_share = s11cq07,
          planting_month = s11cq14b) %>%
   left_join(crop_code,by="crop_code") %>%
   dplyr::select(hhID,fieldID,plotID,crop,crop_area_share,planting_month)%>%
   filter(planting_month %in% seq(1,12))
 
ca <- read_csv(paste0(data.mli,area.file)) %>%
  mutate(hhID = paste(grappe,exploitation,sep="_")) %>%
  rename(fieldID = s11bq01,
         plotID = s11bq02,
         plot_area_measured = s11bq07) %>%
  mutate(plot_area_reported = ifelse(s11bq11b == 1,s11bq11a,s11bq11a/10000)) %>%
  dplyr::select(hhID,fieldID,plotID,plot_area_measured,plot_area_reported)
ca[ca == Inf]=NA

c = c %>%
  left_join(ca,by=c("hhID","fieldID","plotID")) %>%
  mutate(season = NA) %>%
  mutate(source = "MLI_2017_EAC-I_v03_M") %>%
  mutate(country = "Mali")

h <- read.csv(paste0(data.mli,harvesting.file)) %>%
  mutate(hhID = paste(grappe,exploitation,sep="_")) %>%
  rename(fieldID = s7fq01,
         plotID = s7fq02,
         harvest_month_begin = s7fq05b,
         harvest_year_begin = s7fq05c,
         harvest_month_end = s7fq12b,
         harvest_year_end = s7fq12c)
h[h==Inf]=NA

# Averaging of harvesting months is set off.
#h$harvest_month = as.integer((h$harvest_month_begin+h$harvest_month_end)/2)
#h$harvest_year = as.integer((h$harvest_year_begin+h$harvest_year_end)/2)
#h$harvest_month[is.na(h$harvest_month) & is.na(h$harvest_month_end)]=h$harvest_month_begin[is.na(h$harvest_month) & is.na(h$harvest_month_end)]
#h$harvest_month[is.na(h$harvest_month) & is.na(h$harvest_month_begin)]=h$harvest_month_end[is.na(h$harvest_month) & is.na(h$harvest_month_begin)]
h$harvest_month = NA
h$harvest_year = NA
h = h %>%
  dplyr::select(hhID,fieldID,plotID,harvest_month,harvest_year,harvest_month_begin,harvest_month_end,harvest_year_begin,harvest_year_end)

file = c %>%
  left_join(h,by=c("hhID","fieldID","plotID")) %>%
  left_join(bx,by=c("hhID"))

geo = read.csv(paste0(data.mli,geovariables.file)) %>%
  rename(lat = lat_dd_mod,
         lon = lon_dd_mod) %>%
  mutate(GPS_level = 3) %>%
  dplyr::select(grappe,lat,lon,GPS_level)

file = file %>%
  left_join(geo,by="grappe") %>%
  mutate(adm4 = NA) %>%
  mutate(planting_year = ifelse(planting_month >=10,harvest_year-1,harvest_year)) %>%
  rename(plot_area_measured_ha = plot_area_measured,
         plot_area_reported_ha = plot_area_reported,
         dataset_name = source) %>%
  mutate(plot_area_reported_localUnit = NA,
         localUnit_area = NA,
         dataset_doi = "https://doi.org/10.48529/0v50-h966") %>%
  dplyr::select(country,adm1,adm2,adm3,adm4,lat,lon,GPS_level,hhID,fieldID,plotID,crop,season,plot_area_measured_ha,plot_area_reported_ha,
         plot_area_reported_ha,plot_area_reported_localUnit,localUnit_area,crop_area_share,planting_year,planting_month,harvest_month,
         harvest_year,harvest_month_begin,harvest_month_end,harvest_year_begin,harvest_year_end,dataset_name,dataset_doi)

wave2 = file

file = rbind(wave1,wave2)

# # Write output table ------------------------------------------------------
write_csv(wave1,paste0(path.mli,"out/mali_w1.csv"))
write_csv(wave2,paste0(path.mli,"out/mali_w2.csv"))
write_csv(file, paste0(path.mli,"out/mali.csv"))
