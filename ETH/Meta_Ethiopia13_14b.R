metadata <- data.frame(matrix(ncol = 10, nrow = 28))
c_names <- c("country", "year", "varName_harmonized", "varName_source", "varLabel_source", "pctMissing_harmonized", "pctMissing_source", "comment", "dataset_name", "dataset_doi")
colnames(metadata) <- c_names
metadata$country <- "Ethiopia"
metadata$year <- "2013-14"
metadata$varName_harmonized <- colnames(plant_harvest)
metadata$dataset_name <- "ETH_2013_LASER_v02_M "
metadata$dataset_doi <- "https://doi.org/10.48529/9pwg-as66"

metadata$varName_harmonized

#Varname_source
metadata$varName_source=c(
  "household_id2", #"hhID",
  "pp_s4q01_a, ph_s9q0d", #"crop",
  "pp_s4q03", #"crop_area_share",
  "pp_s4q12_a", #"planting_month",
  "pp_s4q12_b", #"planting_year",
  "parcel_id, field_id", #"plotID",
  "ph_s9q07_a", #"harvest_month_begin",
  "ph_s9q07_b", #"harvest_month_end",
  "region", #"adm1",
  "zonename", #"adm2",
  "woredaname", #"adm3",  
  "lat_dd_mod", #"lat",
  "lon_dd_mod", #"lon",
  NA, #"GPS_level",
  "pp_s3q02_a", #"plot_area_reported_localUnit",
  "pp_s3q02_c", #"localUnit_area",
  "pp_s3q05_a", #"plot_area_measured_ha",
  NA, #plot_area_reported_ha",
  NA, #"season",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"harvest_year_begin",
  NA, #"harvest_year_end",
  NA, #"adm4",
  NA, #"fieldID",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#VarLabel_source
metadata$varLabel_source=c(
  "Unique HH ID in wave 2", #"hhID",
  "Crop Name", #"crop",
  "Approximately, how much of the [Field] was planted with [Crop]?", #"crop_area_share",
  "When did you plant the seeds for the [Crop] on this [Field]? (Month)", #"planting_month",
  "When did you plant the seeds for the [Crop] on this [Field]? (EC Year)", #"planting_year",
  "Parcel ID, Field ID", #"plotID",
  "What were the months when the harvest started ?", #"harvest_month_begin",
  "What were the months when the harvest ended?", #"harvest_month_end",
  "Region Name", #"adm1",
  "Zone Name", #"adm2",
  "Woreda Name", #"adm3",
  "lat_dd_mod", #"lat",
  "lon_dd_mod", #"lon",
  NA, #"GPS_level",
  "What is the area of [Field]? (Area)", #"plot_area_reported_localUnit",
  "What is the area of [Field]? (Unit)",  #"localUnit_area",
  "Area of [Field] (Square Meters)", #"plot_area_measured",
  NA, #plot_area_reported_ha",
  NA, #"season",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"harvest_year_begin",
  NA, #"harvest_year_end",
  NA, #"adm4",
  NA, #"fieldID",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#pct_harmonized
trans_ph_na= t(plant_harvest_na)
metadata$pctMissing_harmonized <- c(trans_ph_na)



#comments [,8]
metadata$comment=c(
  NA, #"hhID",
  NA, #"crop",
  NA, #"crop_area_share",
  "values up to 13; the 13th month in Ethiopian calendar", #"planting_month",
  "year 2204 included", #"planting_year",
  "plot_ID may not be unique", #"plotID",
  "values up to 13", #"harvest_month_begin",
  "values up to 13, some months are 0", #"harvest_month_end",
  NA, #"adm1",
  "some zonecodes exist twice because of uppercase and lowercase letters", #"adm2",
  NA, #"adm3",  
  NA, #"lat",
  NA, #"lon",
  NA, #"GPS_level",
  NA, #"plot_area_reported_localUnit",
  NA, #"localUnit_area",
  NA, #"plot_area_measured",
  NA, #plot_area_reported_ha",
  NA, #"season",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"harvest_year_begin",
  NA, #"harvest_year_end",
  NA, #"adm4",
  NA, #"fieldID",
  NA, #"dataset_name",
  NA, #"country",
  "ADDITIONAL COMMENT: no .csv files available; warnings in R code: funs() was deprecated in dplyr 0.8.0." #"dataset_doi"
)

#pct source

conv <- read_sav(paste0(in.path.eth, conversion.file))
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


zb <- read_sav(paste0(in.path.eth, householdidentification.file))
zb <- zb %>% select(household_id2, saq01, saq02, saq03) %>%
  set_names(c("hhID", "regionid", "zoneid", "woredaid")) %>% 
  mutate(zoneid = as.numeric(zoneid),
         woredaid = as.numeric(woredaid)) %>%
  distinct(hhID, .keep_all = TRUE) %>%
  mutate(woredaid = paste(regionid, zoneid, woredaid, sep = "_")) %>%
  mutate(zoneid = paste(regionid, zoneid, sep = "_")) 
zb <- left_join(b, regioncode, by = "regionid", unmatched = 'error') 
zb <- left_join(b, zonecode, by = "zoneid", multiple = "first") 
zb <- left_join(b, woredacode, by = "woredaid") 
zb <- zb %>% distinct(hhID, .keep_all = TRUE) 

mb=zb %>% summarise_all(funs(100*mean(is.na(.))))


zc <- read_sav(paste0(in.path.eth, planting.file))
zc <- zc %>% select(household_id2, parcel_id, field_id, 
                    pp_s4q01_a, pp_s4q03, pp_s4q12_a, pp_s4q12_b) %>%
  set_names(c("hhID", "parcelID", "fieldID", "crop",
              "crop_area_share", "planting_month", "planting_year")) 
mc=zc %>% summarise_all(funs(100*mean(is.na(.))))


zd <- read_sav(paste0(in.path.eth, harvesting.file))
zd <- zd %>% select(household_id2, parcel_id, field_id, ph_s9q0d,
                    ph_s9q07_a, ph_s9q07_b) %>%
  set_names(c("hhID", "parcelID", "fieldID", "crop",
              "harvest_month_begin", "harvest_month_end")) 
md=zd %>% summarise_all(funs(100*mean(is.na(.))))


ze <- read_sav(paste0(in.path.eth, geovariables.file))
ze <- ze %>% select(household_id2, lat_dd_mod, lon_dd_mod) %>%
  set_names(c("hhID", "lat", "lon"))

me=ze %>% summarise_all(funs(100*mean(is.na(.))))


zf <- read_sav(paste0(in.path.eth, field.file))
zf <- zf %>% select(household_id2, parcel_id, field_id, pp_s3q02_a, pp_s3q02_c, pp_s3q05_a) %>%
  set_names(c("hhID", "parcel_ID", "field_ID", 
              "plot_area_reported_localUnit", "localUnit_area", "plot_area_measured_ha")) 
mf=zf %>% summarise_all(funs(100*mean(is.na(.))))

metadata$pctMissing_source=c(
  as.numeric(0), #"hhID",
  as.numeric(0), #"crop",
  as.numeric(mc[1,5]), #"crop_area_share",
  as.numeric(mc[1,6]), #"planting_month",
  as.numeric(mc[1,7]), #"planting_year",
  as.numeric(0), #"plotID",
  as.numeric(md[1,5]), #"harvest_month_begin",
  as.numeric(md[1,6]), #"harvest_month_end",
  as.numeric(0), #"adm1",
  as.numeric(mb[1,6]), #"adm2",
  as.numeric(mb[1,7]), #"adm3",
  as.numeric(me[1,2]), #"lat",
  as.numeric(me[1,3]), #"lon",
  NA, #"GPS_level",
  as.numeric(mf[1,4]), #"plot_area_reported_localUnit",
  as.numeric(mf[1,5]),  #"localUnit_area",
  as.numeric(mf[1,6]), #"plot_area_measured_ha",
  NA, #plot_area_reported_ha",
  NA, #"season",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"harvest_year_begin",
  NA, #"harvest_year_end",
  NA, #"adm4",
  NA, #"fieldID",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)


write_csv(metadata, "out/ETH_2013-14b_metadata.csv")
