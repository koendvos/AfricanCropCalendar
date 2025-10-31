#This code plots planting/harvest years/months per country

rm(list=ls(all=TRUE))
gc()
library(dplyr)
library(tidyverse)
library(readr)
library(ggplot2)

# Read input --------------------------------------------------------------

in.path <- "C:/Users/wahakath/Documents/Research/multiple cropping/LSMS_multiplecropping/PostProcess/"
out.path <- paste0(in.path, "Figures/")
dat.file <- "postprocessed_data.csv"
dat <- read_csv(paste0(in.path, dat.file))

# Look up table for planting and harvest per dataset name / survey --------

#planting year by dataset name / survey
write.csv(table(dat$planting_year, dat$dataset_name),
          file = paste0(out.path, "PlantingYear_by_Survey.csv"))

#planting month by dataset name / survey
write.csv(table(dat$planting_month, dat$dataset_name),
          file = paste0(out.path, "PlantingMonth_by_Survey.csv"))

#harvest year begin by dataset name / survey
write.csv(table(dat$harvest_year_begin, dat$dataset_name),
          file = paste0(out.path, "HarvestYear_by_Survey.csv"))

#harvest month begin by dataset name / survey
write.csv(table(dat$harvest_month_begin, dat$dataset_name),
          file = paste0(out.path, "HarvestMonth_by_Survey.csv"))

# Stacked barplot for planting year by country ----------------------------

#Figure: planting year by country
dat1 <- dat %>% filter(dat$planting_year >= 2000)
dat.figure <- as.data.frame(table(year = dat1$planting_year, 
                                  country = dat1$country))
p1 <- ggplot(dat.figure, aes(fill = country, y= Freq, x = year)) + 
  geom_bar(position = "stack", stat = "identity") +
  scale_fill_brewer(palette = "Paired") +
  theme_minimal() +
  labs(x = "planting year", y = "number of plots") 
png(filename = paste0(out.path, "PlantingYear_by_Country.png"), 
    width = 22, height = 10, res = 300, units ="cm")
print(p1)
dev.off()

#Figure: harvest year begin by country
dat2 <- dat %>% filter(dat$harvest_year_begin >= 2000)
dat.figure <- as.data.frame(table(year = dat2$harvest_year_begin, 
                                  country = dat2$country))
p2 <- ggplot(dat.figure, aes(fill = country, y= Freq, x = year)) + 
  geom_bar(position = "stack", stat = "identity") +
  scale_fill_brewer(palette = "Paired") +
  theme_minimal() +
  labs(x = "harvest year begin", y = "number of plots") 
png(filename = paste0(out.path, "HarvestYearBegin_by_Country.png"), 
    width = 22, height = 10, res = 300, units ="cm")
print(p2)
dev.off()

#Figure: harvest year end by country
dat3 <- dat %>% filter(dat$harvest_year_end >= 2000)
dat.figure <- as.data.frame(table(year = dat3$harvest_year_end, 
                                  country = dat3$country))
p3 <- ggplot(dat.figure, aes(fill = country, y= Freq, x = year)) + 
  geom_bar(position = "stack", stat = "identity") +
  scale_fill_brewer(palette = "Paired") +
  theme_minimal() +
  labs(x = "harvest year end", y = "number of plots") 
png(filename = paste0(out.path, "HarvestYearEnd_by_Country.png"), 
    width = 22, height = 10, res = 300, units ="cm")
print(p3)
dev.off()



