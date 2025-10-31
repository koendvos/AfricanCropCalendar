# Script to plot tree map showing most important crop groups

rm(list=ls(all=TRUE))
gc()

library(treemap)
library(treemapify)
library(stringr)
library(RColorBrewer)

setwd("C:/Users/wahakath/Documents/Research/multiple cropping/LSMS_multiplecropping/")

#read postprocess file
DATA <- read.csv("PostProcess/postprocessed_data.csv")
lookup_data <- read.csv2("PostProcess/crop_lookup.csv")

#filter data for only crops
DATA_filtered <- DATA %>%
  distinct(hhID, crop, .keep_all = TRUE)

#statistics on crop count
crop_counts <- DATA_filtered %>%
  count(crop) %>%
  arrange(desc(n))  
write_csv(crop_counts, "PostProcess/Figures/crop_count.csv") #counts each crop per household once

#statistics on crop group count using FAO categorization in lookup table
DATA_combined <- merge(DATA_filtered, lookup_data, by = "crop", all.x = TRUE)
crop_counts_combi <- DATA_combined %>%
  count(group) %>%
  arrange(desc(n))
write_csv(crop_counts_combi, "PostProcess/Figures/crop_group_count.csv")

# removing unnecessary characters
crop_counts_combi <- crop_counts_combi[!(is.na(crop_counts_combi$group) | crop_counts_combi$group == ""), ]
crop_counts_combi <- crop_counts_combi %>%
  mutate(group = gsub(", n\\.e\\.c\\.", "", group),                
         group = gsub("\\(.*?\\)", "", group))

crop_counts_combi$label <- paste(crop_counts_combi$group, crop_counts_combi$n, sep = ": ")

# only crops > 1000
crop_counts_combi$label <- ifelse(crop_counts_combi$n > 1000,
                                        paste(crop_counts_combi$group, crop_counts_combi$n, sep = ": "),
                                        "")

#as an alternative try with only crops  > 5000
#crop_counts_combi_cleanerer <- crop_counts_combi_cleanerer[crop_counts_combi_cleanerer$n > 5000, ]
#crop_counts_combi_cleanerer$row_num <- 1:nrow(crop_counts_combi_cleanerer)
#crop_counts_combi_cleanerer$label <- str_wrap(crop_counts_combi_cleanerer$label, width = 15)

# with number labels incl. saving
png("PostProcess/Figures/treemap_output_ver2.png", width = 800, height = 600)
treemap(dtf = crop_counts_combi[1:37,],
        index = "group",
        #index = "label",             # Use the combined label for displaying group and n
        vSize = "n",                 # Column to determine the size of each tile
        type = "index",              # Color the tiles based on the index (group)
        palette = brewer.pal(9, 'Reds')[-c(1,2, 9)],                # Choose color palette
        fontsize.labels = 12,        # Adjust font size for labels
        fontcolor.labels = "white",  # Set font color for labels
        bg.labels = "transparent",    # Transparent background for labels
        title = ""
)
dev.off()

