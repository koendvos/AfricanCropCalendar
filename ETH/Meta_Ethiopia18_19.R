metadata <- data.frame(matrix(ncol = 10, nrow = 28))
c_names <- c("country", "year", "varName_harmonized", "varName_source", "varLabel_source", "pctMissing_harmonized", "pctMissing_source", "comment", "dataset_name", "dataset_doi")
colnames(metadata) <- c_names
metadata$country <- "Ethiopia"
metadata$year <- "2018-19"
metadata$varName_harmonized <- colnames(plant_harvest)
metadata$dataset_name <- "ETH_2018_ESS_v03_M"
metadata$dataset_doi <- "https://doi.org/10.48529/k739-c548"

metadata$varName_harmonized

#Varname_source
metadata$varName_source=c(
  "household_id", #"hhID",
  "parcel_id", #"fieldID",
  "field_id", #"plotID",
  "s4q01b, s9q00b", #"crop",
  "s4q03", #"crop_area_share",
  "s4q13a", #"planting_month",
  "s4q13b", #"planting_year",
  "s9q08a", #"harvest_month_begin",
  "s9q08b", #"harvest_month_end",
  "region", #"adm1",
  "zonename", #"adm2",
  "woredaname", #"adm3",  
  "lat_mod", #"lat",
  "lon_mod", #"lon",
  NA, #"GPS_level",
  "s3q02a", #"plot_area_reported_localUnit",
  "s3q02b", #"localUnit_area",
  "s3q08", #"plot_area_measured_ha",
  NA, #plot_area_reported_ha",
  NA, #"season",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"harvest_year_begin",
  NA, #"harvest_year_end",
  NA, #"adm4",
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#VarLabel_source
metadata$varLabel_source=c(
  "Unique Household Indentifier", #"hhID",
  "Unique Parcel Identifier", #"fieldID",
  "Unique Field Identifier", #"plotID",
  "1b.CROP CODE, 1.Crop code", #"crop",
  "3.Approximately, how much of [FIELD] was planted with [CROP]?", #"crop_area_share",
  "13_a.When did you plant the seeds for the [Crop] on [FIELD]? (Month)", #"planting_month",
  "13_b.When did you plant the seeds for the [Crop] on [FIELD]? (Year)", #"planting_year",
  "8a.What was the month when the harvesting of [CROP] on [FIELD] started?", #"harvest_month_begin",
  "8b.What was the month when the harvesting of [CROP] on [FIELD] ended?", #"harvest_month_end",
  "Region", #"adm1",
  "Zone Name", #"adm2",
  "Woreda Name", #"adm3",
  "Latitude Modified", #"lat",
  "Longitude Modified", #"lon",
  NA, #"GPS_level",
  "2a.ASK HOLDER: What is the area of [FIELD]?", #"plot_area_reported_localUnit",
  "2b. Unit of measurement",  #"localUnit_area",
  "8.RECORD AREA OF THE FIELD USING GPS.", #"plot_area_measured",
  NA, #plot_area_reported_ha",
  NA, #"season",
  NA, #"harvest_month",
  NA, #"harvest_year",
  NA, #"harvest_year_begin",
  NA, #"harvest_year_end",
  NA, #"adm4",
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
  "not based on fieldID, but on parcelID", #"fieldID",
  "plot_ID may not be unique, based on fieldID", #"plotID",
  "white cumin and white lumin may be the same crop, crop_name and crop_id don't match", #"crop",
  NA, #"crop_area_share",
  "The value 13 describes the 13th month of the Ethiopian calendar Pagume (6th September - 10th September/ 11th Sepember in leap years)", #"planting_month",
  NA, #"planting_year",
  "The value 13 describes the 13th month of the Ethiopian calendar Pagume (6th September - 10th September/ 11th Sepember in leap years)", #"harvest_month_begin",
  "The value 13 describes the 13th month of the Ethiopian calendar Pagume (6th September - 10th September/ 11th Sepember in leap years)", #"harvest_month_end",
  NA, #"adm1",
  NA, #"adm2",
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
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)

#pct source

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


zb <- read_csv(paste0(in.path.eth, householdidentification.file))
zb <- zb %>% select(household_id, saq01, saq02, saq03) %>%
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


zc <- read_csv(paste0(in.path.eth, planting.file))
zc <- zc %>% select(household_id, parcel_id, field_id, 
                    s4q01b, s4q03, s4q13a, s4q13b) %>%
  set_names(c("hhID", "parcelID", "fieldID", "crop",
              "crop_area_share", "planting_month", "planting_year")) 
mc=zc %>% summarise_all(funs(100*mean(is.na(.))))


zd <- read_csv(paste0(in.path.eth, harvesting.file))
zd <- zd %>% select(household_id, parcel_id, field_id, s9q00b,
                    s9q08a, s9q08b) %>%
  set_names(c("hhID", "parcelID", "fieldID", "crop",
              "harvest_month_begin", "harvest_month_end")) 
md=zd %>% summarise_all(funs(100*mean(is.na(.))))


ze <- read_csv(paste0(in.path.eth, geovariables.file))
ze <- ze %>% select(household_id, lat_mod, lon_mod) %>%
  set_names(c("hhID", "lat", "lon"))

me=ze %>% summarise_all(funs(100*mean(is.na(.))))


zf <- read_csv(paste0(in.path.eth, field.file))
zf <- zf %>% select(household_id, parcel_id, field_id, s3q02a, s3q02b, s3q08) %>%
  set_names(c("hhID", "parcel_ID", "field_ID", 
              "plot_area_reported_localUnit", "localUnit_area", "plot_area_measured_ha")) 
mf=zf %>% summarise_all(funs(100*mean(is.na(.))))

metadata$pctMissing_source=c(
  as.numeric(0), #"hhID",
  as.numeric(0), #"fieldID",
  as.numeric(0), #"plotID",
  as.numeric(0), #"crop",
  as.numeric(mc[1,5]), #"crop_area_share",
  as.numeric(mc[1,6]), #"planting_month",
  as.numeric(mc[1,7]), #"planting_year",
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
  NA, #"dataset_name",
  NA, #"country",
  NA #"dataset_doi"
)


write_csv(metadata, "out/ETH_2018-19_metadata.csv")

##############
#template for comments

# metadata$comment=c(
#"hhID",
#"crop",
#"crop_area_share",
#"planting_month",
#"planting_year",
#"plotID",
#"harvest_month_begin",
#"harvest_month_end",
#"adm1",
#"adm2",
#"adm3",  
#"lat",
#"lon",
#"GPS_level",
#"plot_area_reported_localUnit",
#"localUnit_area",
#"plot_area_measured",
#plot_area_reported_ha",
#"season",
#"harvest_month",
#"harvest_year",
#"harvest_year_begin",
#"harvest_year_end",
#"adm4",
#"fieldID",
#"dataset_name",
#"country",
#"dataset_doi"
# )
# 
# 
