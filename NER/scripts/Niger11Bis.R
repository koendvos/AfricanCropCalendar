# Niger 2014-2015
# Extract information about planting & harvest dates
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

# 2018-19 

# Input files -------------------------------------------------------------
in.path.ner <- "NER_2011_ECVMA_v01_M_SPSS/"

planting.file <- "ecvmaas2b_p1_en.csv" #
householdidentification.file <- "ecvmasection00_p1_en.csv" #Household Identification Particulars
crop.code <- 'crop_conversion.csv'
grappeLocation <- "NER_EA_Offsets.csv"

#geovariables.file <- "eaci_geovariables_2017.csv" #Household GPS coordinates
#conversion.file <- "adm_conversion.csv" #Woreda and Zone code
#area.file <- "ECVMA2_AS1P2.csv" #information on parcel area

# Read input and select variables -----------------------------------------
#Had to create crop.code file

b <- read_csv(paste0(in.path.ner, householdidentification.file))
b <- b %>% select(hid, grappe, ms00q10, ms00q11) %>%
  set_names(c("hhID", "grappe","adm1", "adm2"))

l<- read_csv(paste0(in.path.ner, grappeLocation))%>%
  set_names(c("grappe", "lat","long"))

b <- inner_join(b, l, by = c('grappe' = 'grappe'))

c <- read_csv(paste0(in.path.ner, planting.file))
c <- c %>% select(hid, as02bq01 ,as02bq03,as01qn, as02bq06,   
                  as02bq08, as02bq11) %>%
  set_names(c("hhID", "fieldID","plotNbr","plotID","cropID","plot_area_reported_localUnit",
               "planting_month")) %>%
   filter(planting_month %in% c(1:12)) 

c$localUnit_area="square meters"
c$plot_area_reported_ha=c$plot_area_reported_localUnit/10000

cc<- read_csv(paste0(in.path.ner, crop.code))

c <- inner_join(c, cc, by = c('cropID' = 'crop_code'))


c <- inner_join(b,c, by = c('hhID' = 'hhID'))


c$planting_year <- NA
c$harvesting_month <- NA
c$harvesting_year <- NA
c$plot_area_measured_ha<-NA
c$crop_area_share <-NA
c$dataset_doi <-"https://doi.org/10.48529/bp16-s524"

c$GPS_level <- "Grappe"

c$source <- "NER_2011_ECVMA_V01_M"
c$country <- "Niger"


# Write output table ------------------------------------------------------
write_csv(c, "out/Niger11-12.csv")
