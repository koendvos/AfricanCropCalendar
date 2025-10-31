
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

# Load individual country/survey datasets --------------

# directory containing final datasets 
outData_dir <- file.path(in.path, 'out')
# setwd <- outData_dir

data <- read.csv("PostProcess/postprocessed_data.csv")
# unique(data$adm1) # 298 -> no abbreviations
# unique(data$adm2) # 1475 -> n'guigmi, gaya {added may/04, 07}, samia-bugwe
# unique(data$adm3)  # 3358 -> as adm3 and gadougou 1, bassa (plateau state), nyendo/senyange
# unique(data$adm4) # 2625 -> as above
#keine himmelsrichtungen auf französisch

data$adm1 <- tolower(data$adm1)          
data$adm1 <- stri_trans_general(data$adm1, "Latin-ASCII") 
# 170

data$adm2 <- tolower(data$adm2)
data$adm2 <- stri_trans_general(data$adm2, "Latin-ASCII") 
# 1007

data$adm3 <- tolower(data$adm3)                         
data$adm3 <- stri_trans_general(data$adm3, "Latin-ASCII") 
# 2622

data$adm4 <- tolower(data$adm4)                         
data$adm4 <- stri_trans_general(data$adm4, "Latin-ASCII") 
# 1930


setwd("C:/Users/roetzeso/Documents/GAUL_2024_L2")

# shp_data <- st_read("GAUL_2024_L2.shp")
mli_shp_data <- st_read("mli_admbndp_admALL_1m_gov_itos_20211220.shp") #FR
mwi_shp_data <- st_read("mwi_admbndp_admALL_nso_hotosm_itos_20230405.shp")
eth_shp_data <- st_read("eth_admbndp_admALL_csa_bofedb_itos_2021.shp")
uga_shp_data <- st_read("uga_admbndp_admALL_ubos_itos_20200824.shp")
nga_shp_data <- st_read("nga_admbndp_admALL_osgof_eha_itos_20190417.shp")
ner_shp_data <- st_read("NER_admbndp_admALL_IGNN_itos_20230720.shp") #FR

setwd("C:/Users/roetzeso/Documents/LSMS_multiplecropping")

# names_country <- unique(shp_data$gaul0_name)

# our_countries <- unique(data$country)

# all(our_countries %in% names_country) # sind alle namen in verfügbar in shp?

# #shp tolower and no accents
# shp_data$gaul1_name <- tolower(shp_data$gaul1_name)
# shp_data$gaul2_name <- tolower(shp_data$gaul2_name)
# shp_data$gaul1_name <- stri_trans_general(shp_data$gaul1_name, "Latin-ASCII") 
# shp_data$gaul2_name <- stri_trans_general(shp_data$gaul2_name, "Latin-ASCII") 



#MALI -------------------------------------------------------------

#shp tolower and no accents
mli_shp_data$ADM1_FR <- tolower(mli_shp_data$ADM1_FR)
mli_shp_data$ADM2_FR <- tolower(mli_shp_data$ADM2_FR)
mli_shp_data$ADM3_FR <- tolower(mli_shp_data$ADM3_FR)
mli_shp_data$ADM1_FR <- stri_trans_general(mli_shp_data$ADM1_FR, "Latin-ASCII") 
mli_shp_data$ADM3_FR <- stri_trans_general(mli_shp_data$ADM3_FR, "Latin-ASCII") 
mli_shp_data$ADM2_FR <- stri_trans_general(mli_shp_data$ADM2_FR, "Latin-ASCII") 


#
df_shp <- st_drop_geometry(mli_shp_data)
df_shp <- df_shp[, c("ADM2_FR", 
                     # "ADM1_FR", "ADM3_FR",
                     "POINT_X", "POINT_Y")]
# df_shp <- df_shp %>% rename(adm1 = ADM1_FR)%>% rename(adm2 = ADM2_FR)%>% rename(adm3 = ADM3_FR)
df_shp <- df_shp %>% rename(adm2 = ADM2_FR)

data <- fuzzy_left_join(
  data,
  df_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.1
)
data$adm2.y <- NULL
data <- data %>% rename(adm2 = adm2.x)


# df_test <- data[, c("adm2.x", "adm2.y")]
# df_test <- unique(df_test)
# df_test <- df_test[df_test[[1]] != df_test[[2]], ]

#NIGER -------------------------------------------------------------

#shp tolower and no accents
ner_shp_data$ADM1_FR <- tolower(ner_shp_data$ADM1_FR)
ner_shp_data$ADM2_FR <- tolower(ner_shp_data$ADM2_FR)
ner_shp_data$ADM3_FR <- tolower(ner_shp_data$ADM3_FR)
ner_shp_data$ADM1_FR <- stri_trans_general(ner_shp_data$ADM1_FR, "Latin-ASCII") 
ner_shp_data$ADM3_FR <- stri_trans_general(ner_shp_data$ADM3_FR, "Latin-ASCII") 
ner_shp_data$ADM2_FR <- stri_trans_general(ner_shp_data$ADM2_FR, "Latin-ASCII") 


#
df_shp <- st_drop_geometry(ner_shp_data)
# df_shp <- ner_shp_data
df_shp <- df_shp[, c("ADM2_FR",
                     # "ADM1_FR", "ADM3_FR", 
                     "POINT_X", "POINT_Y")]
# df_shp <- df_shp %>% rename(adm1 = ADM1_FR)%>% rename(adm2 = ADM2_FR)%>% rename(adm3 = ADM3_FR)
df_shp <- df_shp %>% rename(adm2 = ADM2_FR)

data <- fuzzy_left_join(
  data,
  df_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.1
)

data$adm2.y <- NULL
data <- data %>% rename(adm2 = adm2.x)

#NIGERIA -------------------------------------------------------------

#shp tolower and no accents
nga_shp_data$ADM1_EN <- tolower(nga_shp_data$ADM1_EN)
nga_shp_data$ADM2_EN <- tolower(nga_shp_data$ADM2_EN)
nga_shp_data$ADM3_EN <- tolower(nga_shp_data$ADM3_EN)
nga_shp_data$ADM1_EN <- stri_trans_general(nga_shp_data$ADM1_EN, "Latin-ASCII") 
nga_shp_data$ADM3_EN <- stri_trans_general(nga_shp_data$ADM3_EN, "Latin-ASCII") 
nga_shp_data$ADM2_EN <- stri_trans_general(nga_shp_data$ADM2_EN, "Latin-ASCII") 

#
df_shp <- st_drop_geometry(nga_shp_data)
df_shp <- df_shp[, c("ADM2_EN", 
                     # "ADM1_EN", "ADM3_EN", 
                     # "POINT_X", "POINT_Y"
                     "SD_EN" #random column
                     )]
# df_shp <- df_shp %>% rename(adm1 = ADM1_EN)%>% rename(adm2 = ADM2_EN)%>% rename(adm3 = ADM3_EN)
df_shp <- df_shp %>% rename(adm2 = ADM2_EN)

data <- fuzzy_left_join(
  data,
  df_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.15
)

data$adm2.y <- NULL
data <- data %>% rename(adm2 = adm2.x)

#Malawi -------------------------------------------------------------

#shp tolower and no accents
mwi_shp_data$ADM1_EN <- tolower(mwi_shp_data$ADM1_EN)
mwi_shp_data$ADM2_EN <- tolower(mwi_shp_data$ADM2_EN)
mwi_shp_data$ADM3_EN <- tolower(mwi_shp_data$ADM3_EN)
mwi_shp_data$ADM1_EN <- stri_trans_general(mwi_shp_data$ADM1_EN, "Latin-ASCII") 
mwi_shp_data$ADM3_EN <- stri_trans_general(mwi_shp_data$ADM3_EN, "Latin-ASCII") 
mwi_shp_data$ADM2_EN <- stri_trans_general(mwi_shp_data$ADM2_EN, "Latin-ASCII") 




df_shp <- st_drop_geometry(mwi_shp_data)
df_shp <- df_shp[, c("ADM2_EN", 
                     # "ADM1_EN", "ADM3_EN", 
                     # "POINT_X", "POINT_Y"
                     "date" #random column
                     )]
# df_shp <- df_shp %>% rename(adm1 = ADM1_EN)%>% rename(adm2 = ADM2_EN)%>% rename(adm3 = ADM3_EN)
df_shp <- df_shp %>% rename(adm2 = ADM2_EN)

data <- fuzzy_left_join(
  data,
  df_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.15
)

data$adm2.y <- NULL
data <- data %>% rename(adm2 = adm2.x)


#ETH -------------------------------------------------------------

#shp tolower and no accents
eth_shp_data$ADM1_EN <- tolower(eth_shp_data$ADM1_EN)
eth_shp_data$ADM2_EN <- tolower(eth_shp_data$ADM2_EN)
eth_shp_data$ADM3_EN <- tolower(eth_shp_data$ADM3_EN)
eth_shp_data$ADM1_EN <- stri_trans_general(eth_shp_data$ADM1_EN, "Latin-ASCII") 
eth_shp_data$ADM3_EN <- stri_trans_general(eth_shp_data$ADM3_EN, "Latin-ASCII") 
eth_shp_data$ADM2_EN <- stri_trans_general(eth_shp_data$ADM2_EN, "Latin-ASCII") 


df_shp <- st_drop_geometry(eth_shp_data)
df_shp <- df_shp[, c("ADM2_EN", 
                     # "ADM1_EN", "ADM3_EN", 
                     "POINT_X", "POINT_Y")]
# df_shp <- df_shp %>% rename(adm1 = ADM1_EN)%>% rename(adm2 = ADM2_EN)%>% rename(adm3 = ADM3_EN)
df_shp <- df_shp %>% rename(adm2 = ADM2_EN)

data <- fuzzy_left_join(
  data,
  df_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.15
)

data$adm2.y <- NULL
data <- data %>% rename(adm2 = adm2.x)

#Uganda -------------------------------------------------------------

#shp tolower and no accents
uga_shp_data$ADM1_EN <- tolower(uga_shp_data$ADM1_EN)
uga_shp_data$ADM2_EN <- tolower(uga_shp_data$ADM2_EN)
uga_shp_data$ADM3_EN <- tolower(uga_shp_data$ADM3_EN)
uga_shp_data$ADM4_EN <- tolower(uga_shp_data$ADM4_EN)
uga_shp_data$ADM1_EN <- stri_trans_general(uga_shp_data$ADM1_EN, "Latin-ASCII") 
uga_shp_data$ADM3_EN <- stri_trans_general(uga_shp_data$ADM3_EN, "Latin-ASCII") 
uga_shp_data$ADM2_EN <- stri_trans_general(uga_shp_data$ADM2_EN, "Latin-ASCII") 
uga_shp_data$ADM4_EN <- stri_trans_general(uga_shp_data$ADM4_EN, "Latin-ASCII") 

df_shp <- st_drop_geometry(uga_shp_data)
df_shp <- df_shp[, c("ADM2_EN", 
                     # "ADM1_EN", "ADM3_EN", "ADM4_EN",
                     #"POINT_X", "POINT_Y"
                    "validTo" #random column
                     )]
# df_shp <- df_shp %>% rename(adm1 = ADM1_EN)%>% rename(adm2 = ADM2_EN)%>% rename(adm3 = ADM3_EN)
df_shp <- df_shp %>% rename(adm2 = ADM2_EN)

data <- fuzzy_left_join(
  data,
  df_shp,
  by = "adm2",
  match_fun = function(x, y) stringdist::stringdist(x, y, method = "jw") <= 0.15
)

data$adm2.y <- NULL
data <- data %>% rename(adm2 = adm2.x)

#-----------------------------------

data <- data[!is.na(data$hhID), ]
