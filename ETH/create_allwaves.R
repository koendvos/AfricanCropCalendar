#ETH all waves
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

in.path.eth <- "C:/Users/roetzeso/Documents/LSMS_multiplecropping/out/"
ETH2011.file <- "ETH_2011-12.csv" 
ETH2013.file <- "ETH_2013-14.csv" 
ETH2015.file <- "ETH_2015-16.csv" 
ETH2018.file <- "ETH_2018-19.csv"


ETH_2011 <- read_csv(paste0(in.path.eth, ETH2011.file))
ETH_2013 <- read_csv(paste0(in.path.eth, ETH2013.file))
ETH_2015 <- read_csv(paste0(in.path.eth, ETH2015.file))
ETH_2018 <- read_csv(paste0(in.path.eth, ETH2018.file))

#rbind
ETH_bind <- rbind(ETH_2011, ETH_2013, ETH_2015, ETH_2018)

#adjust localUnit_area names
unique_localUnit_area <- unique(ETH_bind$localUnit_area)

mapping <- c("1" = "Hectare",
             "2" = "Square Meters",
             "4" = "Boy",
             "3" = "Timad",
             "5" = "Senga",
             "6" = "Kert",
             "11" = "Other",
             "7" = "Tilm",
             "8" = "Medeb",
             "9" = "Rope(Gemed)",
             "10" = "Ermija",
             "1. Hectare" = "Hectare",
             "2. Square Meters" = "Square Meters",
             "4. Boy" = "Boy",
             "3. Timad" = "Timad",
             "5. Senga" = "Senga",
             "6. Kert" = "Kert",
             "11. Other (Specify)" = "Other",
             "7. Tilm" = "Tilm",
             "8. Medeb" = "Medeb",
             "9. Rope(Gemed)" = "Rope(Gemed)",
             "10. Ermija" = "Ermija",
             "NA" = NA) # Keep NA as NA

ETH_bind$localUnit_area <- ifelse(is.na(ETH_bind$localUnit_area), 
                                  NA, 
                                  mapping[as.character(ETH_bind$localUnit_area)])
unique(ETH_bind$localUnit_area)

#save file
write_csv(ETH_bind, "out/ETH_allWaves.csv")

#same for metadata
meta_ETH2011.file <- "ETH_2011-12_metadata.csv" 
meta_ETH2013.file <- "ETH_2013-14_metadata.csv" 
meta_ETH2015.file <- "ETH_2015-16_metadata.csv" 
meta_ETH2018.file <- "ETH_2018-19_metadata.csv"


meta_ETH_2011 <- read_csv(paste0(in.path.eth, meta_ETH2011.file))
meta_ETH_2013 <- read_csv(paste0(in.path.eth, meta_ETH2013.file))
meta_ETH_2015 <- read_csv(paste0(in.path.eth, meta_ETH2015.file))
meta_ETH_2018 <- read_csv(paste0(in.path.eth, meta_ETH2018.file))

#rbind
meta_ETH_bind <- rbind(meta_ETH_2011, meta_ETH_2013, meta_ETH_2015, meta_ETH_2018)

#save file
write_csv(meta_ETH_bind, "out/ETH_allWaves_metadata.csv")
