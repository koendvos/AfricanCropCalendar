# authors: Sophie Rötzer and Katharina Waha
# create lookup table for adm2 names

rm(list=ls(all=TRUE))
gc()

# Load libraries ----------------------------------------------------------

library(dplyr)
library(sf)
library(stringi)
library(fuzzyjoin)


# Define project folder path and set working directory to project  --------
in.path <- "C:/Users/roetzeso/Documents/LSMS_multiplecropping"
setwd(in.path)


data <- read.csv("PostProcess/AfricanCropCalendar.csv")
# unique(data$adm1) # 298 -> no abbreviations
# unique(data$adm2) # 1475 -> n'guigmi, gaya {added may/04, 07}, samia-bugwe
# unique(data$adm3)  # 3358 -> as adm3 and gadougou 1, bassa (plateau state), nyendo/senyange
# unique(data$adm4) # 2625 -> as above
# no cardinal directions in french



shp_list <- c("mli", "mwi", "eth", "uga", "nga", "ner")
count = 0

for (cur_country in shp_list){
  
  setwd("C:/Users/roetzeso/Documents/GAUL_2024_L2") # redefine path -------------------
  
  if (cur_country == "mli"){
    current_shp <- st_read("mli_admbnda_adm2_1m_gov_20211220.shp") #FR
  } else if (cur_country == "mwi"){
    current_shp <- st_read("mwi_admbnda_adm2_nso_hotosm_20230405.shp")
  } else if (cur_country == "eth"){
    current_shp <- st_read("eth_admbnda_adm2_csa_bofedb_2021.shp")
  } else if (cur_country == "uga"){
    current_shp <- st_read("uga_admbnda_adm2_ubos_20200824.shp")
  } else if (cur_country == "nga"){
    current_shp <- st_read("nga_admbnda_adm2_osgof_20190417.shp")
  } else if (cur_country == "ner"){
    current_shp <- st_read("NER_admbnda_adm2_IGNN_20230720.shp") #FR
  } else {print("error")}
  setwd("C:/Users/roetzeso/Documents/LSMS_multiplecropping") # redefine path -------------------

if (cur_country == "mli" | cur_country == "ner"){
#shp tolower and no accents
current_shp$ADM1_FR <- tolower(current_shp$ADM1_FR)
current_shp$ADM2_FR <- tolower(current_shp$ADM2_FR)
current_shp$ADM1_FR <- stri_trans_general(current_shp$ADM1_FR, "Latin-ASCII") 
current_shp$ADM2_FR <- stri_trans_general(current_shp$ADM2_FR, "Latin-ASCII") 


#Calculate and extract centroid points of adm polygons
#using dplyr to make sure points are added to the right administrative unit
centroid_shp <- st_centroid(current_shp) #calculate centroid coordinates of adm2 polygons
centroid_shp <- centroid_shp %>%
  mutate(lon.hdx = sf::st_coordinates(.)[,1],
         lat.hdx = sf::st_coordinates(.)[,2]) %>%
  select(ADM2_FR, lon.hdx, lat.hdx) %>%
  rename(adm2 = ADM2_FR)
centroid_shp <- st_drop_geometry(centroid_shp)

} else {
  #shp tolower and no accents
  current_shp$ADM1_EN <- tolower(current_shp$ADM1_EN)
  current_shp$ADM2_EN <- tolower(current_shp$ADM2_EN)
  current_shp$ADM1_EN <- stri_trans_general(current_shp$ADM1_EN, "Latin-ASCII") 
  current_shp$ADM2_EN <- stri_trans_general(current_shp$ADM2_EN, "Latin-ASCII") 
  
  
  #Calculate and extract centroid points of adm polygons
  #using dplyr to make sure points are added to the right administrative unit
  centroid_shp <- st_centroid(current_shp) #calculate centroid coordinates of adm2 polygons
  centroid_shp <- centroid_shp %>%
    mutate(lon.hdx = sf::st_coordinates(.)[,1],
           lat.hdx = sf::st_coordinates(.)[,2]) %>%
    select(ADM2_EN, lon.hdx, lat.hdx) %>%
    rename(adm2 = ADM2_EN)
  centroid_shp <- st_drop_geometry(centroid_shp)
}


if(count == 0){
data.joined <- fuzzy_left_join(
  data,
  centroid_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.05
)
data.joined <- data.joined %>% rename(adm2 = adm2.x)%>% 
  rename(adm2.hdx = adm2.y)
} else {
#x from dataset
#y from shp files
        

data.joined <- fuzzy_left_join(
  data.joined,
  centroid_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.05
)
data.joined <- data.joined %>%
  mutate(lat.hdx = coalesce(lat.hdx.x, lat.hdx.y)) %>%  
  mutate(lon.hdx = coalesce(lon.hdx.x, lon.hdx.y)) %>%  
  mutate(adm2.hdx = coalesce(adm2.hdx, adm2.y)) %>%  
  select(-lat.hdx.x, -lat.hdx.y, -lon.hdx.x, -lon.hdx.y, -adm2.y) %>% 
  rename(adm2 = adm2.x)
}


count = count +1
print("one round done")

}


lookup_table <- data.joined %>%
  select(adm2, adm2.hdx, country, lat.hdx, lon.hdx) %>%
  filter(!is.na(adm2) | !is.na(adm2.hdx)) %>%
  distinct()


write.csv(lookup_table, "Coordinates_lookup.csv")