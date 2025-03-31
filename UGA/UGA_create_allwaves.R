#UGA all waves
rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(haven)
library(readxl)

in.path.uga <- "C:/Users/roetzeso/Documents/LSMS_multiplecropping/out/"
#ETH2011.file <- "UGA_2011-12.csv" some files are still missing
UGA2019.file <- "UGA_2019-20.csv" 
UGA2015.file <- "UGA_2015-16.csv" 
UGA2018.file <- "UGA_2018-19.csv"


#ETH_2011 <- read_csv(paste0(in.path.eth, ETH2011.file))
UGA_2019 <- read_csv(paste0(in.path.uga, UGA2019.file))
UGA_2015 <- read_csv(paste0(in.path.uga, UGA2015.file))
UGA_2018 <- read_csv(paste0(in.path.uga, UGA2018.file))

#rbind
UGA_bind <- rbind(UGA_2019, UGA_2015, UGA_2018)

#save file
write_csv(UGA_bind, "out/UGA_allWaves.csv")

#same for metadata
# meta_ETH2011.file <- "ETH_2011-12_metadata.csv" 
meta_UGA_2019.file <- "UGA_2019-20_metadata.csv" 
meta_UGA_2015.file <- "UGA_2015-16_metadata.csv" 
meta_UGA_2018.file <- "UGA_2018-19_metadata.csv"


# meta_ETH_2011 <- read_csv(paste0(in.path.eth, meta_ETH2011.file))
meta_UGA_2019 <- read_csv(paste0(in.path.uga, meta_UGA_2019.file))
meta_UGA_2015 <- read_csv(paste0(in.path.uga, meta_UGA_2015.file))
meta_UGA_2018 <- read_csv(paste0(in.path.uga, meta_UGA_2018.file))

#rbind
meta_UGA_bind <- rbind(meta_UGA_2019, meta_UGA_2015, meta_UGA_2018)

#save file
write_csv(meta_UGA_bind, "out/UGA_allWaves_metadata.csv")
