#Plots coordinates of households per country and arranges all six country
#maps on a 3x2 grid
rm(list=ls(all=TRUE))
gc()

library(readr)
library(sf)
library(tidyverse)
library(mapdata)
library(maps)
library(ggplot2)
library(gridExtra)
library(ggthemes)
library(basemaps)

#read data and convert so spatial dataframe
postprocessed_data <- read_csv("PostProcess/postprocessed_data.csv")
points = st_as_sf(postprocessed_data, coords = c("lon", "lat"), crs = 4326, 
                  na.fail=FALSE)
out.folder <- "PostProcess/Figures/"

# Main --------------------------------------------------------------------

#make individual country maps
uganda <- map_data("world", region="uganda")
uganda.points <- postprocessed_data %>% 
  filter(country=="Uganda") %>%
  filter(!is.na(lat), !is.na(lon)) %>%
  unite("coords", lat:lon, remove = FALSE) %>%
  distinct(coords, .keep_all = TRUE)
gg1 <- ggplot() + 
  geom_polygon(data = uganda, aes(x = long, y = lat, group = group), 
               fill = "white", color = "darkgrey") + 
  coord_quickmap() +
  theme_bw() +
  geom_point(data = uganda.points, aes(x = lon, y = lat), shape = 21, 
             color = "black", fill = "black", size = 1, alpha = 0.4) +
  labs(title="Uganda", x ="lon", y = "lat")

ethiopia <- map_data("world", region="ethiopia")
ethiopia.points <- postprocessed_data %>% 
  filter(country=="Ethiopia") %>%
  filter(!is.na(lat), !is.na(lon)) %>%
  unite("coords", lat:lon, remove = FALSE) %>%
  distinct(coords, .keep_all = TRUE)
gg2 <- ggplot() + 
  geom_polygon(data = ethiopia, aes(x = long, y = lat, group = group), 
               fill = "white", color = "darkgrey") + 
  coord_quickmap() +
  theme_bw() +
  geom_point(data = ethiopia.points, aes(x = lon, y = lat), shape = 21, 
             color = "black", fill = "black", size = 1, alpha = 0.4) +
  labs(title="Ethiopia", x ="lon", y = "lat")

mali <- map_data("world", region="mali")
mali.points <- postprocessed_data %>% 
  filter(country=="Mali") %>%
  filter(!is.na(lat), !is.na(lon)) %>%
  unite("coords", lat:lon, remove = FALSE) %>%
  distinct(coords, .keep_all = TRUE)
gg3 <- ggplot() + 
  geom_polygon(data = mali, aes(x = long, y = lat, group = group), 
               fill = "white", color = "darkgrey") + 
  coord_quickmap() +
  theme_bw() +
  geom_point(data = mali.points, aes(x = lon, y = lat), shape = 21, 
             color = "black", fill = "black", size = 1, alpha = 0.4) +
  labs(title="Mali", x ="lon", y = "lat")

malawi <- map_data("world", region="malawi")
malawi.points <- postprocessed_data %>% 
  filter(country=="Malawi") %>%
  filter(!is.na(lat), !is.na(lon)) %>%
  unite("coords", lat:lon, remove = FALSE) %>%
  distinct(coords, .keep_all = TRUE)
gg4 <- ggplot() + 
  geom_polygon(data = malawi, aes(x = long, y = lat, group = group), 
               fill = "white", color = "darkgrey") + 
  coord_quickmap() +
  theme_bw() +
  geom_point(data = malawi.points, aes(x = lon, y = lat), shape = 21, 
             color = "black", fill = "black", size = 1, alpha = 0.4) +
  labs(title="Malawi", x ="lon", y = "lat")

niger <- map_data("world", region="niger")
niger <- niger %>% filter(region=='Niger')
niger.points <- postprocessed_data %>% 
  filter(country=="Niger") %>%
  filter(!is.na(lat), !is.na(lon)) %>%
  unite("coords", lat:lon, remove = FALSE) %>%
  distinct(coords, .keep_all = TRUE)
gg5 <- ggplot() + 
  geom_polygon(data = niger, aes(x = long, y = lat, group = group), 
               fill = "white", color = "darkgrey") + 
  coord_quickmap() +
  theme_bw() +
  geom_point(data = niger.points, aes(x = lon, y = lat), shape = 21, 
             color = "black", fill = "black", size = 1, alpha = 0.4) +
  labs(title="Niger", x ="lon", y = "lat")

nigeria <- map_data("world", region="nigeria")
nigeria.points <- postprocessed_data %>% 
  filter(country=="Nigeria") %>%
  filter(!is.na(lat), !is.na(lon)) %>%
  unite("coords", lat:lon, remove = FALSE) %>%
  distinct(coords, .keep_all = TRUE)
gg6 <- ggplot() + 
  geom_polygon(data = nigeria, aes(x = long, y = lat, group = group), 
               fill = "white", color = "darkgrey") + 
  coord_quickmap() +
  theme_bw() +
  geom_point(data = nigeria.points, aes(x = lon, y = lat), shape = 21, 
             color = "black", fill = "black", size = 1, alpha = 0.4) +
  labs(title="Nigeria", x ="lon", y = "lat")

#Arrange all in a grid panel
gg7 <- grid.arrange(gg1, gg2, gg3, gg4, gg5, gg6, nrow = 2, ncol = 3)
ggsave(paste(out.folder, "Figure2_alternative.png", sep=""),
             width = 20, height = 20, units = "cm", plot = gg7)