
{
  library(tidyverse)
}

folder = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(folder)

basedir = dirname(folder)
dir_out = paste(basedir,"out/",sep="/")
out_files = list.files(dir_out)
allWaves_list = out_files[grepl("allWaves.csv",out_files)]

template_names = c("country","adm1","adm2","adm3","adm4","lat","lon","GPS_level",
                   "hhID","fieldID","plotID","crop","season","plot_area_measured_ha",
                   "plot_area_reported_ha","plot_area_reported_localUnit","localUnit_area",
                   "crop_area_share","planting_year","planting_month","harvest_month","harvest_year",
                   "harvest_month_begin","harvest_month_end","dataset_name","dataset_doi")

loadAllWave = function(file_name){
  print(paste0("Loading in ",file_name))
  file = fread(paste0(dir_out,file_name))
  
  #Failsafe for Malawi - should be deleted in next versions
  if (file_name == "MWI_allWaves.csv"){
    file = file %>%
      mutate(lat = latitude,
             lon = longitude) %>%
      select(-wave)
  }
  file = file %>%
    select(template_names)
  #Failsafe for correct casting - should be deleted in next versions
  file = file %>%
    mutate(country = as.character(country),
           adm1 = as.character(adm1),
           adm2 = as.character(adm2),
           adm3 = as.character(adm3),
           adm4 = as.character(adm4),
           lat = as.numeric(lat),
           lon = as.numeric(lon),
           GPS_level = as.integer(GPS_level),
           hhID = as.character(hhID),
           fieldID = as.numeric(fieldID),
           plotID = as.numeric(plotID),
           crop = as.character(crop),
           season = as.character(season),
           plot_area_measured_ha = as.numeric(plot_area_measured_ha),
           plot_area_reported_ha = as.numeric(plot_area_reported_ha),
           plot_area_reported_localUnit = as.numeric(plot_area_reported_localUnit),
           localUnit_area = as.character(localUnit_area),
           crop_area_share = as.numeric(crop_area_share),
           planting_year = as.integer(planting_year),
           planting_month = as.integer(planting_month),
           harvest_month = as.integer(harvest_month),
           harvest_year = as.integer(harvest_year),
           harvest_month_begin = as.integer(harvest_month_begin),
           harvest_month_end = as.integer(harvest_month_end),
           #harvest_year_begin = as.integer(harvest_year_begin),
           #harvest_year_end = as.integer(harvest_year_end),
           dataset_name = as.character(dataset_name),
           dataset_doi = as.character(dataset_doi))
  return(file)
}

laps = lapply(allWaves_list, function(file) loadAllWave(file)) %>%
  do.call(rbind,.)
