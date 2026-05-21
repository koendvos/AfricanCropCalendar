#This script merges the individual country and survey data files, 
#inspects and cleans them to create a harmonized dataset
#authors: Uwe Grewer (initially dataMerge.py, later translated to dataMerge.R),
#Sophie Rötzer and Katharina Waha
################################################################################

rm(list=ls(all=TRUE))
gc()

# Load libraries ----------------------------------------------------------

library(dplyr)
library(tidyverse)
library(haven)
library(finalfit)
library(readr)
library(lubridate)
library(sf)
library(arrow)
library(geosphere)
library(ggplot2)
library(stats)
library(data.table)
library(stringi)

# 1 Define project folder path and set working directory to project  --------
in.path <- "<your file path here>"
#in.path.ppd <- paste0(in.path, "LSMS_multiplecropping/PostProcess/")
setwd(in.path)

# 2 Load individual country/survey datasets --------------

# directory containing final datasets 
outData_dir <- file.path(in.path, 'out')

# data collection dates lookup table
data_collection_dates <- read.csv("PostProcess/data_collection_dates.csv", sep = ";")


# load datasets into list
dataset_dct <- list(
  ETH_all_pd = read.csv(file.path(outData_dir, 'ETH_allWaves.csv')),
  MLI_all_pd = read.csv(file.path(outData_dir, 'MLI_allWaves.csv')),
  MWI_all_pd = read.csv(file.path(outData_dir, 'MWI_allWaves.csv')),
  UGA_many_pd = read.csv(file.path(outData_dir, 'UGA_allWaves.csv')),
  UGA_2011_pd = read.csv(file.path(outData_dir, 'uganda11-12.csv')),
  UGA_2013_pd = read.csv(file.path(outData_dir, 'uganda13-14.csv')),
  NGA_2015_pd = read.csv(file.path(outData_dir, 'NGA_2015-16.csv')),
  NGA_2018_pd = read.csv(file.path(outData_dir, 'NGA_2018-19.csv')),
  NGA_2023_pd = read.csv(file.path(outData_dir, 'NGA_2023-24.csv')),
  NER_2011_pd = read.csv(file.path(outData_dir, 'Niger11-12.csv')),
  NER_2014_pd = read.csv(file.path(outData_dir, 'NER_2014-15.csv'))
)

# dataset template
dataset_template_pd <- read.csv(file.path(in.path, 'documentation/dataset_template/dataset_template.csv'))

# target columns list
targetCols_dataset_lst <- colnames(dataset_template_pd)

# 3 Inspect datasets --------------------------------------------------------

# dictionary with descriptive information
datasetsInspect_dct <- list()

# add keys to dictionary
for (key in names(dataset_dct)) {
  datasetsInspect_dct[[substr(key, 1, nchar(key) - 3)]] <- list()
}

# inspect missing columns

# loop over datasets
for (df_string in names(dataset_dct)) {
  df <- dataset_dct[[df_string]]
  
  # print variable type for selected variables
  print(paste0(df_string, " :GPS level is numeric: ", is.numeric(df$GPS_level)))
  
  # list of missing columns
  missingCols_lst_tmp <- c()
  # list of additional, non-target columns
  nontargetCols_dataset_lst_tmp <- c()
  
  # loop over target columns
  for (targetCol in targetCols_dataset_lst) {
    # check if dataset contains target column
    if (!(targetCol %in% colnames(df))) {
      # if missing: record column-name as missing
      missingCols_lst_tmp <- c(missingCols_lst_tmp, targetCol)
    }
  }
  
  # loop over dataset columns
  for (datasetCol in colnames(df)) {
    # check if dataset-column is part of target columns
    if (!(datasetCol %in% targetCols_dataset_lst)) {
      nontargetCols_dataset_lst_tmp <- c(nontargetCols_dataset_lst_tmp, datasetCol)
    }
  }
  
  # store list of missing columns to descriptive dictionary
  datasetsInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$missingCols_lst <- missingCols_lst_tmp
  # store list of additional, non-target columns to descriptive dictionary
  datasetsInspect_dct[[substr(df_string, 1, nchar(df_string) - 3)]]$nontargetCols_dataset_lst <- nontargetCols_dataset_lst_tmp
}

# 4 Harmonize datasets (Niger, Nigeria, Uganda) -------------------------------

# Correct GPS level to be an integer between 1 and 3
for (df_string in names(dataset_dct)) {
  df <- dataset_dct[[df_string]]
  DATA <- dataset_dct[[df_string]]
  DATA <- DATA %>%
  mutate(GPS_level = case_when(
    GPS_level == "3.0" ~ 3,
    GPS_level == "3" ~ 3,
    GPS_level == "Household" ~ 2,
    GPS_level == "EA" ~ 3,
    GPS_level == "adm4" ~ NA,
    GPS_level == "Grappe" ~ 3
    #.default = as.numeric(GPS_level)
  ))
  dataset_dct[[df_string]] <- DATA
}

# rename variables to correspond to template
dataset_dct[['NER_2011_pd']] <- dataset_dct[['NER_2011_pd']] %>%
  rename(
    lon = long,
    harvest_month = harvesting_month,
    harvest_year = harvesting_year,
    dataset_name = source
  )

### Niger (2011)

# set variables genuinely missing in original dataset to NaN
dataset_dct[['NER_2011_pd']]$adm3 <- NA
dataset_dct[['NER_2011_pd']]$adm4 <- NA
dataset_dct[['NER_2011_pd']]$harvest_month_begin <- NA
dataset_dct[['NER_2011_pd']]$harvest_year_begin <- NA
dataset_dct[['NER_2011_pd']]$harvest_month_end <- NA
dataset_dct[['NER_2011_pd']]$harvest_year_end <- NA

# drop redundant variables
dataset_dct[['NER_2011_pd']] <- dataset_dct[['NER_2011_pd']] %>%
  select(-grappe, -plotNbr, -cropID)

# preliminarily, set outstanding variables to NaN
dataset_dct[['NER_2011_pd']]$season <- NA

### Nigeria 

# drop redundant variables
for(dsname in c('NGA_2015_pd', 'NGA_2018_pd', 'NGA_2023_pd')) {
dataset_dct[[dsname]] <- dataset_dct[[dsname]] %>%
  select(-wave, -dm_gender, -gps_meas)

# set variables genuinely missing in original dataset to NaN
dataset_dct[[dsname]]$fieldID <- NA

# set redundant variables to NaN
dataset_dct[[dsname]]$harvest_year <- NA
dataset_dct[[dsname]]$harvest_month <- NA

}

### Uganda (2011)

# rename variables to correspond to template
dataset_dct[['UGA_2011_pd']] <- dataset_dct[['UGA_2011_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude
    #dataset_name = source
  )

# set variables genuinely missing in original dataset to NaN
dataset_dct[['UGA_2011_pd']]$fieldID <- NA

### Uganda (2013)

# rename variables to correspond to template
dataset_dct[['UGA_2013_pd']] <- dataset_dct[['UGA_2013_pd']] %>%
  rename(
    lon = longitude,
    lat = latitude,
    dataset_name = source
  )

# set variables genuinely missing in original dataset to NaN
dataset_dct[['UGA_2013_pd']]$fieldID <- NA

# correct variable name of fully missing variable to correspond to template
dataset_dct[['UGA_2013_pd']] <- dataset_dct[['UGA_2013_pd']] %>%
  rename(
    plot_area_measured_ha = plot_area_measured
  )

# correct variable data types
for (df_string in names(dataset_dct)) {
  dataset_dct[[df_string]]$hhID <- as.character(dataset_dct[[df_string]]$hhID)
  dataset_dct[[df_string]]$fieldID <- as.character(dataset_dct[[df_string]]$fieldID)
  dataset_dct[[df_string]]$plotID <- as.character(dataset_dct[[df_string]]$plotID)
  dataset_dct[[df_string]]$planting_year <- as.character(dataset_dct[[df_string]]$planting_year)
}



# 5 Merge datasets ----------------------------------------------------------

# load all individual dataframes into single dataframe
allData_pd <- bind_rows(dataset_dct)

# make planting year a numeric again
allData_pd$planting_year <- as.numeric(allData_pd$planting_year)

# drop rows that are NaN across all columns
#allData_pd <- allData_pd %>%
#  drop_na(everything())

# only keep rows with at least one non-NA value
allData_pd <- allData_pd %>% 
  filter_all(any_vars(!is.na(.)))
                             
# 6 Begin data correction ---------------------------------------------------

#Descriptive statistics for dataframe before any further manipulation
BEFORE <- ff_glimpse (allData_pd)
CONT_BEFORE <- BEFORE$Continuous
CAT_BEFORE <- BEFORE$Categorical

# 7 Fix crop names ----------------------------------------------------------

#change all uppercase letters to lowercase (reducing the unique variables: 326->252)
allData_pd <- mutate(allData_pd, crop = tolower(crop))

#all unique crop names - alphabetically (can be deleted later on)
unique_crop_1 <- sort(unique(allData_pd$crop)) #901 crops

#start cleaning crop names
allData_pd <- allData_pd %>% 
  mutate (crop = str_replace_all(crop, "agbono\\(oro seed\\)", "agbono \\(oro seed\\)")) %>%
  mutate (crop = str_replace_all(crop, "avacoda", "avocado")) %>%
  mutate (crop = str_replace_all(crop, "avocado pear", "avocado")) %>%
  mutate (crop = str_replace_all(crop, "avocados", "avocado")) %>%
  mutate (crop = str_replace_all(crop, "bananas", "banana")) %>%
  mutate (crop = str_replace_all(crop, "banana beer", "banana \\(beer\\)")) %>%     
  mutate (crop = str_replace_all(crop, "banana sweet", "banana \\(sweet\\)")) %>%   
  mutate (crop = str_replace_all(crop, "banana food", "banana \\(food\\)")) %>% 
  mutate (crop = str_replace_all(crop, "barely", "barley")) %>%
  mutate (crop = str_replace_all(crop, "beans", "bean")) %>%
  mutate (crop = str_replace_all(crop, "bean/cowpea", "cowpea")) %>%
  mutate (crop = str_replace_all(crop, "beeni-seed/sesame", "sesame \\(beeni-seed\\)")) %>%
  mutate (crop = str_replace_all(crop, "calebash", "calabash")) %>%
  mutate (crop = str_replace_all(crop, "cashew", "cashew nut")) %>%
  mutate (crop = str_replace_all(crop, "cashew nut nut", "cashew nut")) %>% 
  mutate (crop = str_replace_all(crop, "cassava old", "cassava \\(old\\)")) %>%
  mutate (crop = str_replace_all(crop, "chilli", "pepper \\(chilli\\)")) %>%               
  mutate (crop = str_replace_all(crop, "chilies", "pepper \\(chilli\\)")) %>%              
  mutate (crop = str_replace_all(crop, "pepper \\(chilli\\) pepper", "pepper \\(chilli\\)")) %>%            
  #mutate (crop = str_replace_all(crop, "chinese cabbage", "cabbage \\(chinese\\)")) %>%
  mutate (crop = str_replace_all(crop, "cocoa pod", "cocoa \\(pod\\)")) %>%
  mutate (crop = str_replace_all(crop, "coco yam", "cocoyam")) %>%
  mutate (crop = str_replace_all(crop, "coffee all", "coffee")) %>%
  # mutate (crop = str_replace_all(crop, "cotton seed", "cotton")) %>%    
  mutate (crop = str_replace_all(crop, "cotton seed", "cotton \\(seed\\)")) %>%        
  mutate (crop = str_replace_all(crop, "cow pea", "cowpea")) %>%
  mutate (crop = str_replace_all(crop, "cow peas", "cowpea")) %>%
  mutate (crop = str_replace_all(crop, "cowpeas", "cowpea")) %>%
  mutate (crop = str_replace_all(crop, "eggplants", "eggplant")) %>%
  mutate (crop = str_replace_all(crop, "fodder cowpea", "cowpea \\(fodder\\)")) %>%
  mutate (crop = str_replace_all(crop, "carrots", "carrot")) %>%
  mutate (crop = str_replace_all(crop, "field peas", "field pea")) %>%
  mutate (crop = str_replace_all(crop, "chick peas", "chick pea")) %>%
  # mutate (crop = str_replace_all(crop, "\\b(acha|fonio)\\b", "acha \\(fonio\\)")) %>%
  # mutate (crop = str_replace_all(crop, "\\b(taro|godere)\\b", "taro \\(godere\\)")) %>%
  mutate (crop = str_replace_all(crop, "grape fruit", "grapefruit")) %>%
  mutate (crop = str_replace_all(crop, "\\b(ground nut/peanuts|ground ?nuts|groundnut|peanut)\\b", "groundnut \\(peanut\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(guinea corn \\(sorghum\\)|guinea courn/sorghum)\\b", "sorghum \\(guinea corn\\)")) %>%
  mutate (crop = str_replace_all(crop, "guinea corn \\(sorghum \\(guinea corn\\)\\)", "sorghum \\(guinea corn\\)")) %>%
  # mutate (crop = str_replace_all(crop, "bambara nut", "bambara groundnut")) %>%
  mutate (crop = str_replace_all(crop, "bambara groundnut \\(peanut\\)", "bambara groundnut")) %>%
  mutate (crop = str_replace_all(crop, "\\b(irish potatoes|potato, irish)\\b", "irish potato")) %>%            
  #mutate (crop = str_replace_all(crop, "kale", "kale \\(leaf cabbage\\)")) %>%
  mutate (crop = str_replace_all(crop, "jaxatu eggplant", "eggplant \\(jaxatu\\)")) %>%
  mutate (crop = str_replace_all(crop, "kolanut unshelled", "kolanut \\(unshelled\\)")) %>%
  mutate (crop = str_replace_all(crop, "red kideny beans", "red kidney bean")) %>%
  mutate (crop = str_replace_all(crop, "red kideny bean", "red kidney bean")) %>%
  mutate (crop = str_replace_all(crop, "leeks", "leek")) %>%
  mutate (crop = str_replace_all(crop, "lemons", "lemon")) %>%
  mutate (crop = str_replace_all(crop, "lentils", "lentil")) %>%
  mutate (crop = str_replace_all(crop, "mandarins", "mandarin")) %>%
  mutate (crop = str_replace_all(crop, "mandarin/tangerine", "mandarin \\(tangerine\\)")) %>%
  mutate (crop = str_replace_all(crop, "mangos", "mango")) %>%
  mutate (crop = str_replace_all(crop, "melon/egusi", "melon \\(egusi\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(millet/maiwa)\\b", "millet \\(maiwa\\)")) %>%
  mutate (crop = str_replace_all(crop, "mung bean/ masho", "mung bean \\(masho\\)")) %>%
  mutate (crop = str_replace_all(crop, "oats", "oat")) %>%
  mutate (crop = str_replace_all(crop, "oil palm tree", "oil palm")) %>%
  mutate (crop = str_replace_all(crop, "okra", "okro")) %>%
  mutate (crop = str_replace_all(crop, "onions", "onion")) %>%
  mutate (crop = str_replace_all(crop, "oranges", "orange")) %>%
  mutate (crop = str_replace_all(crop, "other case crops", "other \\(cash crop\\)")) %>%
  mutate (crop = str_replace_all(crop, "other land", "other \\(land\\)")) %>%
  mutate (crop = str_replace_all(crop, "other root c", "other \\(root c\\)")) %>%
  mutate (crop = str_replace_all(crop, "other cereal", "other \\(cereals\\)")) %>%
  mutate (crop = str_replace_all(crop, "other pulses", "other \\(pulses\\)")) %>%
  mutate (crop = str_replace_all(crop, "other fruits", "other \\(fruits\\)")) %>%
  mutate (crop = str_replace_all(crop, "other vegetable", "other \\(vegetables\\)")) %>%
  mutate (crop = str_replace_all(crop, "other spices", "other \\(spices\\)")) %>%
  mutate (crop = str_replace_all(crop, "other oil seed", "other \\(oil seed\\)")) %>%
  mutate (crop = str_replace_all(crop, "other\\(specify\\)", "other")) %>%
  mutate (crop = str_replace_all(crop, "others", "other")) %>%
  mutate (crop = str_replace_all(crop, "\\b(yam, three leaved|three leave yam)\\b", "yam \\(three leaved\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(yam, yellow|yellow yam)\\b", "yam \\(yellow\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(yam, white|white yam)\\b", "yam \\(white\\)")) %>%         
  mutate (crop = str_replace_all(crop, "water yam", "yam \\(water\\)")) %>%       
  mutate (crop = str_replace_all(crop, "water melon", "watermelon")) %>%        
  mutate (crop = str_replace_all(crop, "white lumin", "white cumin")) %>%
  mutate (crop = str_replace_all(crop, "unshelled groundnut \\(peanut\\)", "groundnut \\(unshelled\\)")) %>%
  mutate (crop = str_replace_all(crop, "unshelled maize\\(cob\\)", "maize \\(unshelled/ cob\\)")) %>%
  mutate (crop = str_replace_all(crop, "unshelled melon", "melon \\(unshelled\\)")) %>%
  mutate (crop = str_replace_all(crop, "unshelled rice\\(paddy\\)", "paddy \\(unshelled rice\\)")) %>%
  mutate (crop = str_replace_all(crop, "tomatoes", "tomato")) %>%
  mutate (crop = str_replace_all(crop, "tobbaco", "tobacco")) %>%
  # mutate (crop = str_replace_all(crop, "temporary gr", "grain \\(temporary\\)")) %>%
  mutate (crop = str_replace_all(crop, "sweet potatoes", "sweet potato")) %>%
  mutate (crop = str_replace_all(crop, "\\b(bell pepper)\\b", "pepper \\(bell\\)")) %>%
  mutate (crop = str_replace_all(crop, "pepper, sweet/bell \\(tatashe\\)", "pepper \\(sweet/ bell/ tatashe\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(sweet pepper)\\b", "pepper \\(sweet\\)")) %>%
  mutate (crop = str_replace_all(crop, "sun flower", "sunflower")) %>%
  mutate (crop = str_replace_all(crop, "sugar cane", "sugarcane")) %>%
  mutate (crop = str_replace_all(crop, "\\b(soyabean|soya bean)\\b", "soybean")) %>%
  mutate (crop = str_replace_all(crop, "shelled maize\\(grain\\)", "maize \\(shelled/ grain\\)")) %>%
  mutate (crop = str_replace_all(crop, "shelled groundnut \\(peanut\\)", "groundnut \\(shelled\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(paw paw|pawpaw)\\b", "pawpaw")) %>%
  mutate (crop = str_replace_all(crop, "peas", "pea")) %>%
  # mutate (crop = str_replace_all(crop, "pepper, chilli pepper \\(shombo\\)", "pepper \\(chilli/ shombo\\)")) %>%
  mutate (crop = str_replace_all(crop, "pepper, pepper \\(chilli\\) \\(shombo\\)", "pepper \\(chilli/ shombo\\)")) %>%
  mutate (crop = str_replace_all(crop, "pepper, small \\(rodo\\)", "pepper \\(small/ rodo\\)")) %>%
  mutate (crop = str_replace_all(crop, "red pepper", "pepper \\(red\\)")) %>%
  mutate (crop = str_replace_all(crop, "black pepper", "pepper \\(black\\)")) %>%
  mutate (crop = str_replace_all(crop, "green pepper", "pepper \\(green\\)")) %>%
  mutate (crop = str_replace_all(crop, "small pepper", "pepper \\(small\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(pigeon pea|pigeon peas|pigeonpea)\\b", "pigeon pea")) %>%
  mutate (crop = str_replace_all(crop, "\\b(pinapples|pineapple|pineapples)\\b", "pineapple")) %>%
  mutate (crop = str_replace_all(crop, "\\b(potato|potatoes)\\b", "potato")) %>%
  mutate (crop = str_replace_all(crop, "\\b(pumpkin leave|pumpkin leaves)\\b", "pumpkin \\(leave\\)")) %>%
  mutate (crop = str_replace_all(crop, "\\b(pumpkin|pumpkins)\\b", "pumpkin")) %>%
  mutate (crop = str_replace_all(crop, "pumpkin fruit", "pumpkin \\(fruit\\)")) %>%
  mutate (crop = str_replace_all(crop, "pumpkin seed", "pumpkin \\(seed\\)")) 

#specific cleaning for Malawi surveys
numbers_to_na <- c("1", "1 50 kg bag", "1 acre", "1 mango tree", "1 pail", "tree permanent plot", "natural tree",  "natural trees","plot ya munda wa ku mtembe" ,"plantain",
                   "10", "100", "12", "15", "19", "2", "2 pail", "20:20 cassava", 
                   "3", "30", "3020580209ld01pakhomor01chimanga", "3381","t01-munda wa chinangwa", 
                   "35", "350", "39", "4", "40", "5", "5 pail", "50 kg", "rg01", "rg01t01",
                   "6", "7", "8", "9", "9999", "t04", "to 1", "to1", "one 50 kg bag", "no tree have been harvested so far", "r01 ", "r01", "rg011" )

allData_pd <- allData_pd %>% mutate(crop = ifelse(crop %in% numbers_to_na, NA, crop))%>%
  mutate(crop = gsub('\"', '', crop))  %>% 
  mutate(crop = gsub('t0|r01 |t01 |t01|t01-|t01_|t02 |t02|t03 |t03|t04 |t04|t05 |t05|to1 |tg01 |tg01t01 |tg02- |tg01| plot|d01 |||||||', '', crop))%>% 
  mutate(crop = gsub('^\\s+|\\s+$|\\.+$', '', crop))%>% 
  mutate(crop = gsub('\\s+', ' ', crop))

allData_pd <- allData_pd %>% 
  mutate (crop = str_replace_all(crop, "- munda wa ku buyo", "munda wa ku buyo)")) %>%
  mutate (crop = str_replace_all(crop, "aavocado|acocado|avocado crop|avocado trees|avocando|avogadro|avodaco|avocadons|avocado tree", "avocado")) %>%
  mutate (crop = str_replace_all(crop, "acacias|accacia|acecia|acassia|accacias|aceicia|alcasia|alcacia|acacia tree|acacia trees|acacia land dwelling|cacia|acacia|aacacia", "acacia")) %>%
  mutate (crop = str_replace_all(crop, "\\[custade apple\\] poza", "poza \\(custard apple\\)"))  %>%
  mutate (crop = str_replace_all(crop, "acacia and ntawa", "mix \\(acacia, ntawa\\)"))  %>%
  mutate (crop = str_replace_all(crop, "acacia mangoes malaina and mpoza", "mix \\(acacia, mango, malaina, mpoza\\)"))  %>%
  mutate (crop = str_replace_all(crop, "apple's|apples", "apple")) %>%
  mutate (crop = str_replace_all(crop, "avacodo pea|avocado pair|avocado pears|avovado pea|avocado pea|avocado peya", "avocado")) %>%
  mutate (crop = str_replace_all(crop, "bambara nut", "bambara groundnut")) %>%
  mutate (crop = str_replace_all(crop, "bamboon", "bamboo")) %>%
  mutate (crop = str_replace_all(crop, "banan", "banana"))%>%
  mutate (crop = str_replace_all(crop, "bananaa|bananaa's|bananaaa|bananaa fruit|bananaa fruits|bananaa tree|bananna|bananaa plantains|bannana", "banana"))%>%
  mutate (crop = str_replace_all(crop, "banana fruit|banana plantains|bananaa|banana fruits|bananaa fruits|bananana", "banana"))%>%
  mutate (crop = str_replace_all(crop, "banana tree|bananas|banana's", "banana"))%>%
  mutate (crop = str_replace_all(crop, "baobab trees|boaboa", "baobab")) %>%
  mutate (crop = str_replace_all(crop, "baobab trees|boaboa", "baobab")) %>%
  mutate (crop = str_replace_all(crop, "baw baw fruits", "baw baw fruit")) %>%
  mutate (crop = str_replace_all(crop, "bladful cassava|buladifulu cassava for tg03", "cassava \\(bladful\\)"))  %>%
  mutate (crop = str_replace_all(crop, "bluegum|bluguem|blue gam|bluegam|blugum|brugum|blugam", "blue gum")) %>%
  mutate (crop = str_replace_all(crop, "acacias", "acacia"))%>%
  mutate (crop = str_replace_all(crop, "cassav|casava|casaava|casasava", "cassava"))%>%
  mutate (crop = str_replace_all(crop, "cassavaa", "cassava"))%>%
  mutate (crop = str_replace_all(crop, "cassava garden|cassava_plot|cassavaa tree|cassavaplot|casssava|cassava crop|cassava tree", "cassava")) %>%
  mutate (crop = str_replace_all(crop, "cassava bwendu", "cassava \\(bwendu\\)"))  %>%
  mutate (crop = str_replace_all(crop, "cassava mbundumale", "cassava \\(mbundumale\\)"))%>%
  mutate (crop = str_replace_all(crop, "cassava bitilisi", "cassava \\(bitilisi\\)"))%>%
  mutate (crop = str_replace_all(crop, "cassava mtutumusi|cassava \\(mkondezi\\) for tg02", "cassava \\(mtutumusi\\)"))%>%
  mutate (crop = str_replace_all(crop, "cassava maize|hybrid maize _cassava|maize _cassava", "mix \\(cassava, maize\\)")) %>%
  mutate (crop = str_replace_all(crop, "chammwamba tree", "chammwamba")) %>%
  mutate (crop = str_replace_all(crop, "coffee, avocado, blue gum, banana peaches papaya tangerine", "mix \\(coffee, avocado, blue gum, banana, peache, papaya, tangerine\\)")) %>%
  mutate (crop = str_replace_all(crop, "cofee \\+ banana", "mix \\(coffee, banana\\)")) %>%
  mutate (crop = str_replace_all(crop, "castade apple|custard apple|custarde apple|custered apple|custade apple|custard apple tree\\(poza\\)", "poza \\(custard apple\\)")) %>%
  mutate (crop = str_replace_all(crop, "poza \\(poza \\(custard apple\\)\\)|poza \\(custard apple\\) tree\\(poza\\)", "poza \\(custard apple\\)")) %>% 
  mutate (crop = str_replace_all(crop, "gomani cassava", "cassava \\(gomani\\)"))%>% 
  mutate (crop = str_replace_all(crop, "granadillas", "granadilla")) %>% 
  mutate (crop = str_replace_all(crop, "halale banana", "banana \\(halale\\)")) %>% 
  mutate (crop = str_replace_all(crop, "research cassava", "cassava \\(research\\)"))%>% 
  mutate (crop = str_replace_all(crop, "lembwendu cassava", "cassava \\(lembwendu\\)"))%>% 
  mutate (crop = str_replace_all(crop, "kombezi cassava|mcassava \\(kombezi\\)", "cassava \\(kombezi\\)"))%>% 
  mutate (crop = str_replace_all(crop, "nkondezi cassava", "cassava \\(nkondezi\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mkondezi cassava|mcassava \\(kombezi\\)", "cassava \\(masungazungu\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mtutumusi cassava", "cassava \\(mtutumusi\\)"))%>% 
  mutate (crop = str_replace_all(crop, "masungazungu cassava|masungazungu cassava for tg02", "cassava \\(mkondezi\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mango maboloma", "mango \\(maboloma\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mango kalisela", "mango \\(kalisela\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mango angono", "mango \\(angono\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mango mango a ku munda wakumtunda", "mango \\(mango a ku munda wakumtunda\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mpapa cassava", "cassava \\(mpapa\\)"))%>% 
  mutate (crop = str_replace_all(crop, "nsewa trees", "nsewa tree"))%>% 
  mutate (crop = str_replace_all(crop, "sungarcane|sungarcane|sugarcanes|sugarcame", "sugarcane"))%>% 
  mutate (crop = str_replace_all(crop, "lemon trees|lemon tree", "lemon"))%>% 
  mutate (crop = str_replace_all(crop, "local mangoes", "mango \\(local\\)")) %>% 
  mutate (crop = str_replace_all(crop, "malayina", "malaina")) %>% 
  mutate (crop = str_replace_all(crop, "naartjes", "naartje")) %>% 
  mutate (crop = str_replace_all(crop, "kachere tree", "kachere"))%>% 
  mutate (crop = str_replace_all(crop, "kadale trees", "kadale"))%>% 
  mutate (crop = str_replace_all(crop, "mkhuthe trees|mkhuthe tree", "mkhuthe"))%>% 
  mutate (crop = str_replace_all(crop, "masau trees|masau tree|masaue|masua|masawu", "masau"))%>% 
  mutate (crop = str_replace_all(crop, "musekese trees", "musekese"))%>% 
  mutate (crop = str_replace_all(crop, "kalama trees", "kalama tree"))%>% 
  mutate (crop = str_replace_all(crop, "muimbi trees", "muimbi tree"))%>% 
  mutate (crop = str_replace_all(crop, "msewa trees", "msewa tree"))%>% 
  mutate (crop = str_replace_all(crop, "mpundu trees", "mpundu tree"))%>% 
  mutate (crop = str_replace_all(crop, "malambe tree|malambe trees", "malambe"))%>% 
  mutate (crop = str_replace_all(crop, "kaluma banana", "banana \\(kaluma\\)"))%>% 
  mutate (crop = str_replace_all(crop, "mango ,blue gum and guava", "mix \\(mango ,blue gum, guava\\)")) %>%
  mutate (crop = str_replace_all(crop, "mango and banana", "mix \\(mango, banana\\)")) %>%
  mutate (crop = str_replace_all(crop, "mango and avocado", "mix \\(mango, avocado\\)")) %>%
  mutate (crop = str_replace_all(crop, "mango and guava", "mix \\(mango, guava\\)")) %>%
  mutate (crop = str_replace_all(crop, "mango and naphini", "mix \\(mango, naphini\\)")) %>%
  mutate (crop = str_replace_all(crop, "mango a pakhomo|mango pakhomo", "mix \\(mango, pakhomo\\)")) %>%
  mutate (crop = str_replace_all(crop, "mango, naartje", "mix \\(mango, naartje\\)")) %>%
  mutate (crop = str_replace_all(crop, "mangoes and banana", "mix \\(mango, banana\\)")) %>%
  mutate (crop = str_replace_all(crop, "moringa\\(chammwamba\\)", "moringa \\(chammwamba\\)")) %>%
  mutate (crop = str_replace_all(crop, "kantchidwi trees", "kantchidwi tree")) %>%
  mutate (crop = str_replace_all(crop, "apple", "apples")) %>%
  mutate (crop = str_replace_all(crop, "india banana", "banana (india)")) %>%
  mutate (crop = str_replace_all(crop, "kenya banana", "banana (kenya)")) %>%
  mutate (crop = str_replace_all(crop, "gesha coffee", "coffee (gesha)")) %>%
  mutate (crop = str_replace_all(crop, "english maize", "maize (english)")) %>%
  mutate (crop = str_replace_all(crop, "pearl millet", "millet (pearl)")) %>%
  mutate (crop = str_replace_all(crop, "awpaw (papaya)", "papaya (pawpaw)")) %>%
  mutate (crop = str_replace_all(crop, "pawpaw", "papaya (pawpaw)")) %>%
  mutate (crop = str_replace_all(crop, "pawpaw (papaya)", "papaya")) %>%
  mutate (crop = str_replace_all(crop, "irish potato", "potato (irish)")) %>%
  mutate (crop = str_replace_all(crop, "naartje (tangerine)", "tangerine (naartje)"))%>%
  mutate (crop = str_replace_all(crop, "zanzabar banana", "banana (zanzabar)")) %>%
  mutate (crop = str_replace_all(crop, "zambia banana", "banana (zambia)")) %>%
  mutate (crop = str_replace_all(crop, "sugercane", "sugarcane")) %>%
  mutate (crop = str_replace_all(crop, "mulberry", "mulberries")) %>%
  mutate (crop = str_replace_all(crop, "mexican apples", "apples (mexican)")) %>%
  mutate (crop = str_replace_all(crop, "mbundumale cassava", "cassava (mbundumale)"))
  
allData_pd <- allData_pd %>%
  mutate(crop = ifelse(grepl("^poza$", crop), "poza (custard apple)", crop))%>%
  mutate(crop = ifelse(grepl("^eucalyptus globus|eucalyptus globus(blue gum)|blue gum$", crop), "blue gum (eucalyptus globus)", crop))%>%
  mutate(crop = ifelse(grepl("^fruit trees|fruits$", crop), "fruit", crop))%>%
  mutate(crop = ifelse(grepl("^fruits mmunda$", crop), "mmunda (fruit)", crop))%>%
  mutate(crop = ifelse(grepl("^fuel trees|fuel wood trees|fuel tree|fuel wood tree$", crop), "fuel wood tree", crop))%>%
  mutate(crop = ifelse(grepl("^guava|gauva|guava trees|guava tree|guave|guavant|gwuava|guaves|guavas|guarva$", crop), "guava", crop))%>%
  mutate(crop = ifelse(grepl("^woody trees$", crop), "woody tree", crop))%>%
  mutate(crop = ifelse(grepl("^vocado$", crop), "avocado", crop)) %>%
  mutate(crop = ifelse(grepl("^orange tree|orange trees$", crop), "orange", crop))%>%
  mutate(crop = ifelse(grepl("^sauti cassava|sauti cassava jnk$", crop), "cassava (sauti)", crop)) %>%
  mutate(crop = ifelse(grepl("^thupula cassava$", crop), "cassava (thupula)", crop)) %>%
  mutate(crop = ifelse(grepl("^topotopo|topito|topetope|topitopi|thopithopi|thopethope$", crop), "topetope", crop)) %>%
  mutate(crop = ifelse(grepl("^tea and pineapple$", crop), "mix (tea and pineapple)", crop))%>%
  mutate(crop = ifelse(grepl("^tea trees$", crop), "tea (tree)", crop))%>%
  mutate(crop = ifelse(grepl("^tangalines tree|tangerines|tanjerines|tangarine|tangerine trees|tanjaren$", crop), "tangerine", crop))%>%
  mutate(crop = ifelse(grepl("^mango tress|mango tree|mango trees|mango es|mangoe|mango fruit|mongoes|mqngo|mongoe trees|mngo|mamgoes|mamgo|mango ld01|mangoeplot|mangoes (5)|mangoes garden|mangoes trees|mangomango|mangp|magoe|mangoes tree|mangoes|mangoe trees|mangoes,|mangotree$", crop), "mango", crop))%>%
  mutate(crop = ifelse(grepl("^pakkhomo$", crop), "pakhomo", crop))%>%
  mutate(crop = ifelse(grepl("^pears$", crop), "pear", crop))%>%
  mutate(crop = ifelse(grepl("^mandalena trees$", crop), "mandalena", crop))%>%
  mutate(crop = ifelse(grepl("^peach crop|peach trees|peaches tree|peach tree|peaches trees|peaches$", crop), "peach", crop)) %>%
  mutate(crop = ifelse(grepl("^papaya's|papaya trees|papaaya|papaya tree|papayas|payaya$", crop), "papaya", crop)) %>%
  mutate(crop = ifelse(grepl("^powpow|papaw|pawapaw|paw paw|pawpaw tree|pawpaw. tree|pawpaws|pawpaw trees$", crop), "pawpaw", crop)) %>%
  mutate(crop = ifelse(grepl("^pawpaw /papaya|pawpaw/papaya$", crop), "awpaw (papaya)", crop)) %>%
  mutate(crop = ifelse(grepl("^masuku mexican apple|mexican apple [masuku]|mexican apple masuku|mexican apple (masuku)$", crop), "masuku (mexican apple)", crop)) %>%
  mutate(crop = ifelse(grepl("^masuku tree|masuku trees|masuku,$", crop), "masuku", crop)) %>%
  mutate(crop = ifelse(grepl("^mexan apple|maxicane apple|maxican apple|mexican aple|mexican apple|mexcan apple$", crop), "mexican apple", crop)) %>%
  mutate(crop = ifelse(grepl("^pichesi trees|piches$", crop), "pichesi", crop)) %>%
  mutate(crop = ifelse(grepl("^pine apple|pinaaples$", crop), "pineapple", crop))%>%
  mutate(crop = ifelse(grepl("^mkhobo tree|mkhobo trees$", crop), "mkhobo", crop))%>%
  mutate(crop = ifelse(grepl("^macademia nuts|macadamia nut$", crop), "macadamia", crop))%>%
  mutate(crop = ifelse(grepl("^munda wa ku buyo)$", crop), "munda wa ku buyo", crop))%>%
  mutate(crop = ifelse(grepl("^masuku & avocado$", crop), "mix (masuku, avocado)", crop))%>%
  mutate(crop = ifelse(grepl("^m'bale$", crop), "mbale", crop))%>%
  mutate(crop = ifelse(grepl("^m'bawa$", crop), "mbawa", crop))%>%
  mutate(crop = ifelse(grepl("^plums$", crop), "plum", crop)) 

allData_pd <- allData_pd %>% 
  mutate (crop = str_replace_all(crop, "celcius|calcius", "calcius"))%>% 
  mutate (crop = str_replace_all(crop, "chavwanga cassava for", "cassava"))%>% 
  mutate (crop = str_replace_all(crop, "glicidia|glisidia|glylicidia", "glylicidia"))%>% 
  mutate (crop = str_replace_all(crop, "kumagombwa", "kumagombe"))%>% 
  mutate (crop = str_replace_all(crop, "kuminda", "kumunda"))%>% 
  mutate (crop = str_replace_all(crop, "sindileya|sendeleya|senderera|cindirela", "sendeleya"))%>% 
  mutate (crop = str_replace_all(crop, "mpakasa", "mphakasa"))

allData_pd$crop[allData_pd$crop == ""] <- NA

unique_crop <- sort(unique(allData_pd$crop)) #445 unique crop names after cleaning


# 8 Clean plotID and fieldID in Malawi surveys ------------------------------

original_na_rows <- which(is.na(allData_pd$fieldID))

new_nas <- which(is.na(allData_pd$fieldID))
new_na_rows <- setdiff(new_nas, original_na_rows)
print(new_na_rows)

# 9 Correct months and years in Ethiopia surveys ----------------------------

# recoding month 13 as September in Ethiopia

allData_pd <- allData_pd %>%
  mutate(planting_year = case_when(
    country == "Ethiopia" ~ planting_year + 7,
    TRUE ~ planting_year
  ))

allData_pd <- allData_pd %>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 13, 9, harvest_month_begin)) %>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 13, 9, planting_month)) %>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 13, 9, harvest_month_end)) %>%
  mutate(harvest_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month == 13, 9, harvest_month))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 1, 9, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 2, 10, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 3, 11, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 4, 12, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 5, 1, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 6, 2, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 7, 3, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 8, 4, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 9, 5, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 10, 6, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 11, 7, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_begin == 12, 8, harvest_month_begin))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 1, 9, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 2, 10, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 3, 11, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 4, 12, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 5, 1, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 6, 2, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 7, 3, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 8, 4, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 9, 5, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 10, 6, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 11, 7, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & harvest_month_end == 12, 8, harvest_month_end))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 1, 9, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 2, 10, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 3, 11, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 4, 12, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 5, 1, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 6, 2, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 7, 3, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 8, 4, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 9, 5, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 10, 6, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 11, 7, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & dataset_name != "ETH_2018_ESS_v03_M" & planting_month == 12, 8, planting_month))



# 10 Correct crop area share -------------------------------------------------

#crop_area_share set to a value between 0 and 100 otherwise NA
allData_pd <- allData_pd %>%
  mutate(crop_area_share = 
           if_else(crop_area_share >= 0 & crop_area_share <= 100, 
                   crop_area_share, NA_integer_))
  

# 11 Correct planting and harvesting dates -----------------------------------

#NAs before 
na_before_hyb <- sum(is.na(allData_pd[["harvest_year_begin"]]))
na_before_hye <- sum(is.na(allData_pd[["harvest_year_end"]]))
na_before_hmb <- sum(is.na(allData_pd[["harvest_month_begin"]]))
na_before_hme <- sum(is.na(allData_pd[["harvest_month_end"]]))
na_before_py <- sum(is.na(allData_pd[["planting_year"]]))
na_before_pm <- sum(is.na(allData_pd[["planting_month"]]))

# 12 Cleaning for Uganda surveys ---------------------------------------------

allData_pd <- allData_pd %>%
  # Create logical vectors for each condition
  mutate(
    condition_1 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_begin >= 1 & harvest_month_begin <= 12 &
      harvest_year_begin != 2014,
    
    condition_2 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_begin >= 13 & harvest_month_begin <= 24 &
      harvest_year_begin == 2015,
    
    condition_3 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_begin >= 25 & harvest_month_begin <= 27 &
      harvest_year_begin == 2016,
    
    condition_4 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_begin >= 13 & harvest_month_begin <= 24 &
      harvest_year_begin != 2015,
    
    condition_5 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_begin >= 25 & harvest_month_begin <= 27 &
      harvest_year_begin != 2016,
    
    # Apply conditions to modify the dataframe
    harvest_month_begin = if_else(condition_1, NA_real_, 
                                  if_else(condition_4, NA_real_, 
                                          if_else(condition_5, NA_real_, 
                                                  if_else(condition_2, harvest_month_begin - 12,
                                                          if_else(condition_3, harvest_month_begin - 24, harvest_month_begin))))),
    harvest_year_begin = ifelse(condition_1, NA_real_,
                                ifelse(condition_4, NA_real_,
                                       ifelse(condition_5, NA_real_, harvest_year_begin))))

# Remove the helper columns
allData_pd <- allData_pd %>%
  select(-condition_1, -condition_2, -condition_3, -condition_4, -condition_5)

subset_allData_pd <- allData_pd %>%
  filter(country == "Uganda" & harvest_month_begin >= 13 & harvest_month_begin <= 24)
unique(subset_allData_pd$dataset_name)

allData_pd <- allData_pd %>%
  # Create logical vectors for each condition
  mutate(
    condition_1 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_end >= 1 & harvest_month_end <= 12 &
      harvest_year_end != 2014,
    
    condition_2 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_end >= 13 & harvest_month_end <= 24 &
      harvest_year_end == 2015,
    
    condition_3 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_end >= 25 & harvest_month_end <= 27 &
      harvest_year_end == 2016,
    
    condition_4 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_end >= 13 & harvest_month_end <= 24 &
      harvest_year_end != 2015,
    
    condition_5 = dataset_name == "UGA_2015_UNPS_v02_M" &
      harvest_month_end >= 25 & harvest_month_end <= 27 &
      harvest_year_end != 2016,
    
    # Apply conditions to modify the dataframe
    harvest_month_end = if_else(condition_1, NA_real_, 
                                  if_else(condition_4, NA_real_, 
                                          if_else(condition_5, NA_real_, 
                                                  if_else(condition_2, harvest_month_end - 12,
                                                          if_else(condition_3, harvest_month_end - 24, harvest_month_end))))),
    harvest_year_end = ifelse(condition_1, NA_real_,
                                ifelse(condition_4, NA_real_,
                                       ifelse(condition_5, NA_real_, harvest_year_end))))

# Remove the helper columns
allData_pd <- allData_pd %>%
  select(-condition_1, -condition_2, -condition_3, -condition_4, -condition_5)

subset_allData_pd <- allData_pd %>%
  filter(country == "Uganda" & harvest_month_end >= 13 & harvest_month_end <= 24)
unique(subset_allData_pd$dataset_name)


# 13 General cleaning of dates -----------------------------------------------

# add begin and end of survey
data_collection_dates <- data_collection_dates %>%
  select (-dataset_name, -country)

allData_pd <- allData_pd %>%
  left_join(data_collection_dates, by = "dataset_doi")

# set years and months recorded as 0 to na
# set years referencing the future (e.g., year 8000) to na
# no planting dates after the harvest dates
# no planting or harvesting years before 1900 
# no planting and harvest year after end of the survey

#planting year

allData_pd <- allData_pd %>%
  # Create logical vectors for each condition
  mutate(
    condition_1 = planting_year < 1900 & !is.na(planting_year) , #py, pm raus
    
    condition_2 = planting_year > harvest_year_begin & !is.na(planting_year) & !is.na(harvest_year_begin), #py, pm, hyb, hmb raus
    
    condition_3 = planting_year > harvest_year_end & !is.na(planting_year) & !is.na(harvest_year_end), #py, pm, hye, hme raus
    
    condition_4 = planting_year > End_year & !is.na(planting_year), #py, pm raus
    
    condition_5 = planting_year == harvest_year_begin & #py, pm, hyb, hmb raus
      planting_month > harvest_month_begin & !is.na(planting_year) & !is.na(harvest_month_begin) & !is.na(harvest_year_begin),
    
    condition_6 = planting_year == harvest_year_end & #py, pm, hye, hme raus
      planting_month > harvest_month_end & !is.na(planting_year) & !is.na(harvest_month_end) & !is.na(harvest_year_end) & !is.na(planting_month),
    
    # Apply conditions to modify the dataframe
    planting_year = if_else(condition_1, NA_real_,
                            if_else(condition_2, NA_real_,
                                    if_else(condition_3, NA_real_,
                                            if_else(condition_4, NA_real_,
                                                    if_else(condition_5, NA_real_,
                                                            if_else(condition_6, NA_real_,planting_year)))))),
    planting_month = if_else(condition_1, NA_real_,
                            if_else(condition_2, NA_real_,
                                    if_else(condition_3, NA_real_,
                                            if_else(condition_4, NA_real_,
                                                    if_else(condition_5, NA_real_,
                                                            if_else(condition_6, NA_real_,planting_month)))))),
    harvest_year_begin = if_else(condition_2, NA_real_,
                            if_else(condition_5, NA_real_,harvest_year_begin)),
    harvest_month_begin = if_else(condition_2, NA_real_,
                                 if_else(condition_5, NA_real_,harvest_month_begin)),
    harvest_year_end = if_else(condition_3, NA_real_,
                                 if_else(condition_6, NA_real_,harvest_year_end)),
    harvest_month_end = if_else(condition_3, NA_real_,
                                 if_else(condition_6, NA_real_,harvest_month_end)),
    )

# # Remove the helper columns
allData_pd <- allData_pd %>%
  select(-condition_1, -condition_2, -condition_3, -condition_4, -condition_5, -condition_6)


# harvest_year_begin
allData_pd <- allData_pd %>%
  # Create logical vectors for each condition
  mutate(
    condition_1 = harvest_year_begin < 1900 & !is.na(harvest_year_begin), #hyb, hmb raus
    
    condition_3 = harvest_year_begin > harvest_year_end & !is.na(harvest_year_begin) & !is.na(harvest_year_end), #hyb, hmb, hye, hme raus
    
    condition_4 = harvest_year_begin > End_year & !is.na(harvest_year_begin), #hyb, hmb raus
    
    condition_6 = harvest_year_begin == harvest_year_end & #hyb, hmb, hye, hme raus
      harvest_month_begin > harvest_month_end & !is.na(harvest_year_end) & !is.na(harvest_month_end) & !is.na(harvest_month_begin) & !is.na(harvest_year_begin),
    
    # Apply conditions to modify the dataframe
    harvest_year_begin = if_else(condition_1, NA_real_,
                                    if_else(condition_3, NA_real_,
                                            if_else(condition_4, NA_real_,
                                                            if_else(condition_6, NA_real_,harvest_year_begin)))),
    harvest_month_begin = if_else(condition_1, NA_real_,
                                     if_else(condition_3, NA_real_,
                                             if_else(condition_4, NA_real_,
                                                             if_else(condition_6, NA_real_,harvest_month_begin)))),

    harvest_year_end = if_else(condition_3, NA_real_,
                               if_else(condition_6, NA_real_,harvest_year_end)),
    harvest_month_end = if_else(condition_3, NA_real_,
                                if_else(condition_6, NA_real_,harvest_month_end))
  )

# Remove the helper columns
allData_pd <- allData_pd %>%
  select(-condition_1, -condition_3, -condition_4, -condition_6)


# harvest_year_end
allData_pd <- allData_pd %>%
  # Create logical vectors for each condition
  mutate(
    condition_1 = harvest_year_end < 1900 & !is.na(harvest_year_end), #hye, hme raus !!!!!!!!!!!!!!!!!!!! #weil Malawi oft 2008
    
    condition_4 = harvest_year_end > End_year & !is.na(harvest_year_end), #hye, hme raus
    
    # Apply conditions to modify the dataframe
    harvest_year_end = if_else(condition_1, NA_real_,
                                         if_else(condition_4, NA_real_,harvest_year_end)),
    harvest_month_end = if_else(condition_1, NA_real_,
                                          if_else(condition_4, NA_real_,harvest_month_end))
  )

# # Remove the helper columns
allData_pd <- allData_pd %>%
  select(-condition_1, -condition_4)

# 14 Checking NAs for dates --------------------------------------------------

#NAs after this
na_after_hyb <- sum(is.na(allData_pd[["harvest_year_begin"]]))
na_after_hye <- sum(is.na(allData_pd[["harvest_year_end"]]))
na_after_hmb <- sum(is.na(allData_pd[["harvest_month_begin"]]))
na_after_hme <- sum(is.na(allData_pd[["harvest_month_end"]]))
na_after_py <- sum(is.na(allData_pd[["planting_year"]]))
na_after_pm <- sum(is.na(allData_pd[["planting_month"]]))

#the difference
na_difference_hyb <- na_after_hyb - na_before_hyb
na_difference_hye <- na_after_hye - na_before_hye
na_difference_hmb <- na_after_hmb - na_before_hmb
na_difference_hme <- na_after_hme - na_before_hme
na_difference_py <- na_after_py - na_before_py
na_difference_pm <- na_after_pm - na_before_pm

# Print the result
cat("Number of NAs in column harvest_year_begin raises from", na_before_hyb, "to", na_after_hyb, "\n")
cat("The difference of NAs is", na_difference_hyb, "\n")
cat("Number of NAs in column harvest_year_end raises from", na_before_hye, "to", na_after_hye, "\n")
cat("The difference of NAs is", na_difference_hye, "\n")
cat("Number of NAs in column harvest_month_begin raises from", na_before_hmb, "to", na_after_hmb, "\n")
cat("The difference of NAs is", na_difference_hmb, "\n")
cat("Number of NAs in column harvest_month_end raises from", na_before_hme, "to", na_after_hme, "\n")
cat("The difference of NAs is", na_difference_hme, "\n")
cat("Number of NAs in column planting_year raises from", na_before_py, "to", na_after_py, "\n")
cat("The difference of NAs is", na_difference_py, "\n")
cat("Number of NAs in column planting_month raises from", na_before_pm, "to", na_after_pm, "\n")
cat("The difference of NAs is", na_difference_pm, "\n")


# 15 Correct harvest and planting months -------------------------------------

# set month >12 or <1 to nan
allData_pd <- allData_pd %>%
  mutate(harvest_month_begin = if_else(harvest_month_begin >= 1 & harvest_month_begin <= 12, harvest_month_begin, NA_integer_)) %>%
  mutate(harvest_month_end = if_else(harvest_month_end >= 1 & harvest_month_end <= 12, harvest_month_end, NA_integer_)) %>%
  mutate(harvest_month = if_else(harvest_month >= 1 & harvest_month <= 12, harvest_month, NA_integer_)) %>%
  mutate(planting_month = if_else(planting_month >= 1 & planting_month <= 12, planting_month, NA_integer_))

#after more months were excluded
#NAs after this
na_end_hmb <- sum(is.na(allData_pd[["harvest_month_begin"]]))
na_end_hme <- sum(is.na(allData_pd[["harvest_month_end"]]))
na_end_pm <- sum(is.na(allData_pd[["planting_month"]]))

#the difference
na_difference2_hmb <- na_end_hmb - na_before_hmb
na_difference2_hme <- na_end_hme - na_before_hme
na_difference2_pm <- na_end_pm - na_before_pm

#difference step 2
na_difference3_hmb <- na_end_hmb - na_after_hmb
na_difference3_hme <- na_end_hme - na_after_hme
na_difference3_pm <- na_end_pm - na_after_pm

# Print the result
cat("Number of NAs in column harvest_month_begin raises from", na_after_hmb, "to", na_end_hmb, "\n")
cat("The difference of NAs is", na_difference2_hmb, "\n")
cat("The difference of NAs in step 2 is", na_difference3_hmb, "\n")
cat("Number of NAs in column harvest_month_end raises from", na_after_hme, "to", na_end_hme, "\n")
cat("The difference of NAs is", na_difference2_hme, "\n")
cat("The difference of NAs in step 2 is", na_difference3_hme, "\n")
cat("Number of NAs in column planting_month raises from", na_after_pm, "to", na_end_pm, "\n")
cat("The difference of NAs is", na_difference2_pm, "\n")
cat("The difference of NAs in step 2 is", na_difference3_pm, "\n")

# Remove the additional columns from the join with data_collection_dates
allData_pd <- allData_pd %>%
  select(-End_year, -End_month, -Begin_year , -Begin_month)

# 16 Harmonize missing value identifier --------------------------------------

# set likely missing value identifiers for all variables to nan (99, 9999, 999999, 99.9999)

allData_pd <- allData_pd %>%
  mutate(
    adm2 = if_else(adm2 == "9999" & country == 'Uganda', NA, adm2),
    adm4 = if_else(adm4 == "9999" & country == 'Uganda', NA, adm4),
    
    plot_area_measured_ha = if_else(plot_area_measured_ha == 99 & country == 'Mali', NA, plot_area_measured_ha),
    plot_area_reported_ha = if_else(plot_area_reported_ha == 99 & country == 'Mali', NA, plot_area_reported_ha),
    plot_area_reported_localUnit = if_else(plot_area_reported_localUnit == 99 & country == 'Mali' , NA, plot_area_reported_localUnit),
    
    plot_area_measured_ha = if_else(plot_area_measured_ha == 99.9999 & country == 'Niger', NA, plot_area_measured_ha),
    plot_area_reported_ha = if_else(plot_area_reported_ha == 99.9999 & country == 'Niger', NA, plot_area_reported_ha),
    plot_area_reported_localUnit = if_else(plot_area_reported_localUnit == 999999 & country == 'Niger' , NA, plot_area_reported_localUnit)
  )


# 17 Correct plot_area_measured ----------------------------------------------

# set negative areas to nan (if any)
allData_pd <- allData_pd %>%
  mutate(plot_area_measured_ha=ifelse(plot_area_measured_ha < 0, 
                                      NA, plot_area_measured_ha))


# 18 Correct lat and lon -----------------------------------------------------

# set lat/lon 0/0 or nan/0 or 0/nan to missing
sum(is.na(allData_pd[["lon"]]))/nrow(allData_pd) * 100
sum(is.na(allData_pd[["lat"]]))/nrow(allData_pd) * 100

allData_pd <- allData_pd %>%
  mutate(lat = if_else(lat == 0 & lon == 0, NA_real_, lat),
         lon = if_else(lat == 0 & lon == 0, NA_real_, lon))

#NA_percentage
na_lon <- sum(is.na(allData_pd[["lon"]]))/nrow(allData_pd) * 100
na_lat <- sum(is.na(allData_pd[["lat"]]))/nrow(allData_pd) * 100

print("NA percentage of lon and lat")
sum(is.na(allData_pd[["lon"]]))/nrow(allData_pd) * 100
sum(is.na(allData_pd[["lat"]]))/nrow(allData_pd) * 100

# first adm then NA
print("percentage of lat-NAs with adm3 values")
filtered_df <- allData_pd[!is.na(allData_pd[["adm3"]]), ]
sum(is.na(filtered_df[["lat"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm4 values")
filtered_df <- allData_pd[!is.na(allData_pd[["adm4"]]), ]
sum(is.na(filtered_df[["lat"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm2 values")
filtered_df <- allData_pd[!is.na(allData_pd[["adm2"]]), ]
sum(is.na(filtered_df[["lat"]])) / nrow(filtered_df)*100

#first NA, then adm
print("percentage of lat-NAs with adm2 values")
filtered_df <- allData_pd[is.na(allData_pd[["lat"]]), ]
sum(!is.na(filtered_df[["adm2"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm3 values")
sum(!is.na(filtered_df[["adm3"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm4 values")
sum(!is.na(filtered_df[["adm4"]])) / nrow(filtered_df)*100

## adm3 = NA, but not adm4
filtered_df <- allData_pd[is.na(allData_pd[["adm3"]]) & !is.na(allData_pd[["adm4"]]), ]
nrow(filtered_df)
# -> only in UGA 2011

# 19 Harmonize localUnit_area ------------------------------------------------
allData_pd <- mutate(allData_pd, localUnit_area = tolower(localUnit_area))
allData_pd <- allData_pd %>% 
  mutate (localUnit_area = case_when(
    localUnit_area %in% c("acres", "acre") ~ "acres",
    localUnit_area %in% c("square metre", "square metres", "square meters") ~ "square metres",
    localUnit_area %in% c("other", "other \\(specify\\)") ~ "other",
    localUnit_area %in% c("hectare", "hectares") ~ "hectares",
    localUnit_area %in% c(".a", "0") ~ NA_character_,
    grepl("rope\\(gemed\\)", localUnit_area) ~ "rope (gemed)",
    TRUE ~ localUnit_area
  ))
unique(sort(allData_pd$localUnit_area))

# 20 Correct adm4 and GPS level in Nigeria -----------------------------------

# Set all values of 'adm4' to NA where 'country' is "Nigeria"
# as unclear codes were used
allData_pd$adm4[allData_pd$country == "Nigeria"] <- NA

# show surveys with non-NA lat/lon coordinates but unknown GPS level
filtered_allData_pd <- allData_pd %>%
  filter(!is.na(lat) & !is.na(lon) & is.na(GPS_level))
unique(filtered_allData_pd$dataset_name)

# Set all values of 'GPS_level' to 4 (unknown) where 'country' is "Nigeria"
# allData_pd$GPS_level[allData_pd$country == "Nigeria"] <- NA
# allData_pd$GPS_level <- as.character(allData_pd$GPS_level)
allData_pd <- allData_pd %>%
  mutate(GPS_level = if_else(country == "Nigeria" & 
                               !is.na(lat) & !is.na(lon), 4, GPS_level))

# 21 Set all names to lowercase letters without french spelling adm1, adm2, adm3, adm4  -----------------------------------
allData_pd$adm1 <- tolower(allData_pd$adm1)          
allData_pd$adm1 <- stri_trans_general(allData_pd$adm1, "Latin-ASCII") 
# 170

allData_pd$adm2 <- tolower(allData_pd$adm2)
allData_pd$adm2 <- stri_trans_general(allData_pd$adm2, "Latin-ASCII") 
# 1007

allData_pd$adm3 <- tolower(allData_pd$adm3)                         
allData_pd$adm3 <- stri_trans_general(allData_pd$adm3, "Latin-ASCII") 
# 2622

allData_pd$adm4 <- tolower(allData_pd$adm4)                         
allData_pd$adm4 <- stri_trans_general(allData_pd$adm4, "Latin-ASCII") 


# 22 Remove columns and rows without observations ----------------------------

# remove columns without any values - does not exist, no columns removed
allData_pd <- allData_pd %>%
  select(where(~!all(is.na(.))))

# only keep rows with minimum valid data
# valid = has to have crop type or crop area share or planting month 
# or planting year or harvest month or harvest year
allData_pd <- allData_pd %>%
  filter(!is.na(crop) | !is.na(crop_area_share) | !is.na(planting_month) | 
             !is.na(planting_year) | !is.na(harvest_month_begin) | 
             !is.na(harvest_month_end) | !is.na(plot_area_reported_localUnit) | 
             !is.na(localUnit_area) | !is.na(plot_area_measured_ha) | 
             !is.na(harvest_year_end) | !is.na(plot_area_reported_ha) | 
             !is.na(harvest_year_begin))

# 23 Correct dataset names for Malawi ----------------------------------------
allData_pd <- allData_pd %>%
  mutate(dataset_name = case_when(
    dataset_name == "mwi_2010_ihs-iii_v01_m" ~ "MWI_2010_IHS-III_v01_M",
    dataset_name == "mwi_2010-2013_ihps_v01_m" ~ "MWI_2010-2013_IHPS_v01_M",
    dataset_name == "mwi_2016_ihs-iv_v04_m" ~ "MWI_2016_IHS-IV_v04_M",
    dataset_name == "mwi_2019_ihs-v_v05_m" ~ "MWI_2019_IHS-V_v05_M",
    TRUE ~ dataset_name  # Keep other values unchanged
  ))
unique(allData_pd$dataset_name)

# 24 Remove rows without crop names ------------------------------------------

# removes about 24.000 rows without crop names
allData_pd <- allData_pd %>% filter(!is.na(crop))

# 25 Write output ------------------------------------------------------------
AFTER <- ff_glimpse (allData_pd)
CONT_AFTER <- AFTER$Continuous
CAT_AFTER <- AFTER$Categorical
write_csv(allData_pd, "AfricanCropCalendar.csv")

