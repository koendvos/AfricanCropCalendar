# Script to plot circular plot of most important crops and crop groups 

rm(list=ls(all=TRUE))
gc()

#libararies
library(dplyr)
library(tidyverse)
library(haven)
library(finalfit)
library(readr)
library(fmsb)
library(ggplot2)
library(ggiraphExtra)

setwd("C:/Users/wahakath/Documents/Research/multiple cropping/LSMS_multiplecropping/")

#read postprocess file
DATA <- read.csv("PostProcess/postprocessed_data.csv")
lookup_data <- read.csv2("PostProcess/crop_lookup.csv")

#filter data for only crops
DATA_filtered <- DATA %>%
  distinct(hhID, crop, .keep_all = TRUE)

#make crop counts and save them
crop_counts <- DATA_filtered %>%
  count(crop) %>%
  arrange(desc(n))  
write_csv(crop_counts, "PostProcess/Figures/crop_count.csv") #counts each crop per household once

#crop counts per country
DATA_filtered %>%
  filter(country == 'Malawi') %>%
  count(crop) %>%
  arrange(desc(n))  
  

# ------------------------not all crops can be categorized---------------------------------------------------
#crop counts and groups
DATA_combined <- merge(DATA_filtered, lookup_data, by = "crop", all.x = TRUE)
crop_counts_combi <- DATA_combined %>%
  count(group) %>%
  arrange(desc(n))
write_csv(crop_counts_combi, "PostProcess/Figures/crop_group_count.csv")

# ---------------------------------------------------------------------------------------------------------

#only crops with >1000
crop_counts <- crop_counts[crop_counts$n > 1000, ]
crop_counts <- crop_counts %>% filter(!is.na(crop))

crop_counts_combi <- crop_counts_combi[crop_counts_combi$n > 1000, ]
crop_counts_combi <- crop_counts_combi %>% filter(!is.na(group))


###### renaming the crop_count_combi for plots
crop_counts_combi <- crop_counts_combi %>% 
  mutate (group = str_replace_all(group, "Other roots and tubers, n.e.c.", "Other roots and tuber")) %>%
  mutate (group = str_replace_all(group, "Other cereals, n.e.c.", "Other cereals")) %>%
  mutate (group = str_replace_all(group, "Chillies and peppers \\(capsicum spp.\\)", "Chillies and peppers")) %>%
  mutate (group = str_replace_all(group, "Other crops, n.e.c.", "Other crops")) %>%
  mutate (group = str_replace_all(group, "Other leafy or stem vegetables, n.e.c.", "Other leafy or stem vegetables")) %>%
  mutate (group = str_replace_all(group, "Other stimulant crops, n.e.c.", "Other stimulant crops")) 

#\n

crop_counts_combi <- crop_counts_combi %>% 
  mutate (group = str_replace_all(group, "Pumpkin, squash and gourds", "Pumpkin, squash\nand gourds")) %>%
  mutate (group = str_replace_all(group, "Other permanent medicinal, pesticidal or similar crops", "Other permanent medicinal,\npesticidal or\nsimilar crops")) %>%
  mutate (group = str_replace_all(group, "Mangoes, guavas and mangosteens", "Mangoes, guavas\nand mangosteens")) %>%
  mutate (group = str_replace_all(group, "Other leafy or stem vegetables", "Other leafy or\nstem vegetables")) 


############################# Circle plot code in case someone cares (Version 4 missing because it didn't work) ###################

# # VER 6 ggRadar
# #grey background, red points, overlapping crop names
# 
# df <- crop_counts
# 
# df_long <- df %>%
#   dplyr::mutate(id = 1) %>%
#   tidyr::pivot_wider(names_from = crop, values_from = n) %>%
#   dplyr::select(-id)
# 
# df_long <- rbind(rep(max(df_long, na.rm = TRUE), ncol(df_long)),
#                  rep(min(df_long, na.rm = TRUE), ncol(df_long)),
#                  df_long)
# 
# p <- ggRadar(df_long,
#         grid.min = min(df$n), grid.mid = mean(df$n), grid.max = max(df$n),
#         axis.label.size = 4, group.line.width = 1, group.point.size = 2,
#         background.circle.colour = "white",
#         axis.label.offset = 1.1)
# 
# x11()
# p



# # Ver 5.1 and 5.2 oder: radar mit fmsb
# # overlapping crop names, white background, two designs for radar chart
# 
# max_n <- max(crop_counts$n)
# min_n <- min(crop_counts$n)
# 
# radar_data <- rbind(
#   max_n,  
#   min_n,  
#   crop_counts$n     
# )
# 
# # as dataframe
# radar_data <- as.data.frame(radar_data)
# rowy <- c(crop_counts$crop)
# colnames(radar_data) <- rowy
# 
# x11()
# radarchart(radar_data)
# 
# x11()
# radarchart(radar_data,
#            axistype = 1,              # Type of axis (1 for normal)
#            pcol = rgb(0.2, 0.5, 0.5, 0.9),  # Color of the plot
#            pfcol = rgb(0.2, 0.5, 0.5, 0.5), # Fill color
#            plwd = 2,                   # Line width
#            cglcol = "grey",            # Grid line color
#            cglty = 1,                  # Grid line type
#            axislabcol = "black",       # Axis label color
#            caxislabels = seq(min_n, max_n, length.out = 5),  # Axis labels
#            vlcex = 0.8)

 
# #Ver 3: sqrt
# # overlapping crop names, bars, white background
# plt <- ggplot(crop_counts, aes(x = reorder(crop, n), y = n, fill = crop)) +
#   geom_col(position = "dodge", alpha = 0.9) +  # Use geom_col to create bars
#   # geom_text(aes(label = n), vjust = -0.5, size = 3) +  # Add counts as text labels
#   coord_polar() +  # Convert to polar coordinates
#   theme_minimal() +  # Optional: Use a minimal theme
#   # labs(x = "Crop", y = "Count", title = "Crop Occurrences") +  # Labels and title
#   guides(fill = FALSE)  # Hide legend for fill
# 
# sections <- c(10, 100, 1000, 10000, 50000)
# 
# 
# plt <- plt +
#   scale_y_sqrt(
#     breaks = sections,
#     labels = sections,
#     limits = c(0, sections[length(sections)]),
#     # expand = c(0, 0)  # Ensure no padding in the radial axis
#   ) #+
# # coord_polar()  # Convert to polar coordinates
# 
# # Print the plot
# x11()  
# print(plt)



# #Ver 2
# # overlapping crop names, very weird scale, bars, white background
# plt <- ggplot(crop_counts, aes(x = reorder(crop, n), y = n, fill = crop)) +
#   geom_col(position = "dodge", alpha = 0.9) +  # Use geom_col to create bars
#   # geom_text(aes(label = n), vjust = -0.5, size = 3) +  # Add counts as text labels
#   coord_polar() +  # Convert to polar coordinates
#   theme_minimal() +  # Optional: Use a minimal theme
#   # labs(x = "Crop", y = "Count", title = "Crop Occurrences") +  # Labels and title
#   guides(fill = FALSE)  # Hide legend for fill
# 
# 
# # Custom breaks and limits for the radial axis
# custom_breaks <- c(0, 10, 100, 10000, 50000)
# custom_limits <- c(0, 50000)
# 
# plt <- plt +
#   scale_y_continuous(transform = "log") +
#   coord_polar()
# 
# x11()
# plt



 
# #Ver 1
# # code partly written with crop_counts_combi not with crop_counts, overlapping crop names, hard to read, white background
# plt <- ggplot(crop_counts, aes(x = reorder(crop, n), y = n, fill = crop)) +
#   geom_col(position = "dodge", alpha = 0.9) +  
#   # geom_text(aes(label = n), vjust = -0.5, size = 3) + 
#   coord_polar() +  
#   theme_minimal() +  
#   # labs(x = "Crop", y = "Count", title = "Crop Occurrences") + 
#   guides(fill = FALSE) 
# 
# x11()
# plt
#
# #ver1.2
# plt <- ggplot(crop_counts_combi, aes(x = reorder(group, n), y = n, fill = "red")) +
#   geom_col(position = "dodge", alpha = 0.9) + 
#   coord_polar() + 
#   theme_minimal() + 
#   scale_y_continuous(breaks = c(1000, 10000, 50000),  
#                      labels = c("1k", "10k", "50k")) +  
#   guides(fill = FALSE) 
# 
# x11()
# plt
# 
# #ver1.3
# plt <- ggplot(crop_counts_combi, aes(x = reorder(group, n), y = n, fill = "red")) +
#   geom_col(position = "dodge", alpha = 0.9) +  
#   coord_polar() +  
#   theme_minimal() +  
#   scale_y_continuous(breaks = c(1000, 10000, 50000),  
#                      labels = c("1k", "10k", "50k")) + 
#   theme(
#     axis.text.y = element_text(hjust = 1, size = 12), 
#     axis.text.x = element_text(angle = 0, size = 10) 
#   ) +
#   guides(fill = FALSE) 
# 
# x11()
# plt
# 
# #ver1.4
# plt <- ggplot(crop_counts_combi, aes(x = reorder(group, n), y = n)) +
#   geom_col(position = "dodge", alpha = 0.9, fill = "red") +
#   coord_polar(theta = "x", start = 0) +
#   theme_minimal() +
#   scale_y_continuous(
#     breaks = c(1000, 10000, 50000),
#     labels = c("1k", "10k", "50k"),
#     limits = c(0, 60000),
#     expand = c(0, 0)
#   ) +
#   guides(fill = FALSE) +
#   labs(title = "Crop Occurrences", x = NULL, y = NULL) +
#   theme(
#     axis.text.y = element_text(size = 12, color = "black"),
#     axis.text.x = element_text(size = 10, angle = 0, hjust = 0.5, color = "black"),
#     panel.grid.major = element_line(color = "grey80"),
#     panel.grid.minor = element_blank(),
#     plot.title = element_text(hjust = 0.5, size = 16, face = "bold")
#   )
# 
# x11()
# print(plt)
#
# #ver1.5
# plt <- ggplot(crop_counts_combi, aes(x = reorder(group, n), y = n, fill = "grey")) +
#   geom_col(position = "dodge", alpha = 0.9) +  
#   coord_polar() +  
#   theme_bw() +  
#   scale_y_continuous(trans = "log10",  
#                      breaks = c(1000, 10000, 50000),  
#                      labels = c("1,000", "10,000", "50,000")) +  
#   theme(
#     axis.text.y = element_text(hjust = 1, size = 12), 
#     axis.text.x = element_text(angle = 0, size = 10) 
#   ) +
#   guides(fill = FALSE)  
# 
# x11()
# plt
# 
# #ver1.7
# plt <- ggplot(crop_counts_combi, aes(x = reorder(group, n), y = n, fill = "red")) +
#   geom_col(position = "dodge", alpha = 0.9) +  
#   coord_polar() + 
#   theme_minimal() + 
#   scale_y_continuous(trans = "log10",  
#                      breaks = c(1000, 10000, 50000),  
#                      labels = c("1k", "10k", "50k")) +  
#   theme(
#     axis.text.y = element_text(size = 12, angle = 0, hjust = 0.5, vjust = 0.5),  
#     axis.text.x = element_text(angle = 0, size = 10), 
#     panel.grid.major = element_blank(), 
#     panel.grid.minor = element_blank()  
#   ) +
#   guides(fill = FALSE) 
# 
# x11()
# plt