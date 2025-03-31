rm(list=ls(all=TRUE))
gc()

library(dplyr)
library(tidyverse)
library(haven)
library(finalfit)
library(readr)

in.path <- "C:/Users/wahakath/Documents/Research/multiple cropping/"
#in.path <- "C:/Users/roetzeso/Documents/
in.path.ppd <- paste0(in.path, "LSMS_multiplecropping/PostProcess/")
METADATA.file <- "metadata_merged.csv" 
DATA.file <- "data_merged.csv" 
dates_file <- "data_collection_dates.csv"
DATA <- read_csv(paste0(in.path.ppd, DATA.file))
METADATA.file <- read_csv(paste0(in.path.ppd, METADATA.file))
data_collection_dates <- read_delim((paste0(in.path.ppd, dates_file)), delim = ";")

BEFORE <- ff_glimpse (DATA)
CONT_BEFORE <- BEFORE$Continuous
CAT_BEFORE <- BEFORE$Categorical

############################### crop list #############################################
#change all uppercase letters to lowercase (reducing the unique variables: 326->252)
DATA <- mutate(DATA, crop = tolower(crop))

#all unique crop names - alphabetically (can be deleted later on)
unique_crop_1 <- sort(unique(DATA$crop)) #901 crops

#start cleaning crop names
DATA <- DATA %>% 
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

DATA <- DATA %>% mutate(crop = ifelse(crop %in% numbers_to_na, NA, crop))%>%
  mutate(crop = gsub('\"', '', crop))  %>% 
  mutate(crop = gsub('t0|r01 |t01 |t01|t01-|t01_|t02 |t02|t03 |t03|t04 |t04|t05 |t05|to1 |tg01 |tg01t01 |tg02- |tg01| plot|d01 |||||||', '', crop))%>% 
  mutate(crop = gsub('^\\s+|\\s+$|\\.+$', '', crop))%>% 
  mutate(crop = gsub('\\s+', ' ', crop))

DATA <- DATA %>% 
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
  
DATA <- DATA %>%
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

DATA <- DATA %>% 
  mutate (crop = str_replace_all(crop, "celcius|calcius", "calcius"))%>% 
  mutate (crop = str_replace_all(crop, "chavwanga cassava for", "cassava"))%>% 
  mutate (crop = str_replace_all(crop, "glicidia|glisidia|glylicidia", "glylicidia"))%>% 
  mutate (crop = str_replace_all(crop, "kumagombwa", "kumagombe"))%>% 
  mutate (crop = str_replace_all(crop, "kuminda", "kumunda"))%>% 
  mutate (crop = str_replace_all(crop, "sindileya|sendeleya|senderera|cindirela", "sendeleya"))%>% 
  mutate (crop = str_replace_all(crop, "mpakasa", "mphakasa"))

DATA$crop[DATA$crop == ""] <- NA

unique_crop <- sort(unique(DATA$crop)) #445 unique crop names after cleaning

############################### MWI pltId and fieldID #############################################
original_na_rows <- which(is.na(DATA$fieldID))

DATA <- DATA %>%
  mutate(plotID = case_when(
    plotID %in% c("d01", "d1") ~ 11,
    plotID %in% c("d00", "d0") ~ 10,
    plotID %in% c("d02", "d2") ~ 12,
    plotID %in% c("d03", "d3") ~ 13,
    plotID %in% c("d04", "d4") ~ 14,
    plotID %in% c("d05", "d5") ~ 15,
    plotID %in% c("d06", "d6") ~ 16,
    plotID %in% c("d07", "d7") ~ 17,
    plotID %in% c("d08", "d8") ~ 18,
    plotID %in% c("d09", "d9") ~ 19,
    plotID %in% c("r01", "r1") ~ 11,
    plotID %in% c("r00", "r0") ~ 10,
    plotID %in% c("r02", "r2") ~ 22,
    plotID %in% c("r03", "r3") ~ 23,
    plotID %in% c("r04", "r4") ~ 24,
    plotID %in% c("r05", "r5") ~ 25,
    plotID %in% c("r06", "r6") ~ 26,
    plotID %in% c("r07", "r7") ~ 27,
    plotID %in% c("r08", "r8") ~ 28,
    plotID %in% c("r09", "r9") ~ 29,
    plotID %in% c("t01", "t1") ~ 31,
    plotID %in% c("t00", "t0") ~ 30,
    plotID %in% c("t02", "t2") ~ 32,
    plotID %in% c("t03", "t3") ~ 33,
    plotID %in% c("t04", "t4") ~ 34,
    plotID %in% c("t05", "t5") ~ 35,
    plotID %in% c("t06", "t6") ~ 36,
    plotID %in% c("t07", "t7") ~ 37,
    plotID %in% c("t08", "t8") ~ 38,
    plotID %in% c("t09", "t9") ~ 39,
    TRUE ~ as.numeric(plotID)  # Keep other values intact
  ))


DATA <- DATA %>%
  mutate(fieldID = case_when(
    fieldID %in% c("dg01", "d1") ~ 101,
    fieldID %in% c("dg11", "d0") ~ 111,
    fieldID %in% c("dg12", "d0") ~ 112,
    fieldID %in% c("dg13", "d0") ~ 113,
    fieldID %in% c("dg14", "d0") ~ 114,
    fieldID %in% c("dg02", "d2") ~ 102,
    fieldID %in% c("dg03", "d3") ~ 103,
    fieldID %in% c("dg04", "d4") ~ 104,
    fieldID %in% c("dg05", "d5") ~ 105,
    fieldID %in% c("dg06", "d6") ~ 106,
    fieldID %in% c("dg07", "d7") ~ 107,
    fieldID %in% c("dg08", "d8") ~ 108,
    fieldID %in% c("dg09", "d9") ~ 109,
    fieldID %in% c("dg10", "d9") ~ 100,
    fieldID %in% c("rg01", "d1") ~ 201,
    fieldID %in% c("rg11", "d0") ~ 211,
    fieldID %in% c("rg12", "d0") ~ 212,
    fieldID %in% c("rg13", "d0") ~ 213,
    fieldID %in% c("rg14", "d0") ~ 214,
    fieldID %in% c("rg02", "d2") ~ 202,
    fieldID %in% c("rg03", "d3") ~ 203,
    fieldID %in% c("rg04", "d4") ~ 204,
    fieldID %in% c("rg05", "d5") ~ 205,
    fieldID %in% c("rg06", "d6") ~ 206,
    fieldID %in% c("rg07", "d7") ~ 207,
    fieldID %in% c("rg08", "d8") ~ 208,
    fieldID %in% c("rg09", "d9") ~ 209,
    fieldID %in% c("rg10", "d9") ~ 200,
    fieldID %in% c("tg01", "d1") ~ 301,
    fieldID %in% c("tg11", "d0") ~ 311,
    fieldID %in% c("tg12", "d0") ~ 312,
    fieldID %in% c("tg13", "d0") ~ 313,
    fieldID %in% c("tg14", "d0") ~ 314,
    fieldID %in% c("tg02", "d2") ~ 302,
    fieldID %in% c("tg03", "d3") ~ 303,
    fieldID %in% c("tg04", "d4") ~ 304,
    fieldID %in% c("tg05", "d5") ~ 305,
    fieldID %in% c("tg06", "d6") ~ 306,
    fieldID %in% c("tg07", "d7") ~ 307,
    fieldID %in% c("tg08", "d8") ~ 308,
    fieldID %in% c("tg09", "d9") ~ 309,
    fieldID %in% c("tg10", "d9") ~ 300,
    TRUE ~ as.numeric(fieldID)  # Keep other values intact
  ))

new_nas <- which(is.na(DATA$fieldID))
new_na_rows <- setdiff(new_nas, original_na_rows)
print(new_na_rows)

############################### ETH month #############################################
# recoding month 13 as September in Ethiopia
 
DATA <- DATA %>%
  mutate(planting_year = case_when(
    country == "Ethiopia" ~ planting_year + 7,
    TRUE ~ planting_year
  ))

DATA <- DATA %>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 13, 9, harvest_month_begin)) %>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 13, 9, planting_month)) %>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 13, 9, harvest_month_end)) %>%
  mutate(harvest_month = if_else(country == "Ethiopia" & harvest_month == 13, 9, harvest_month))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 1, 9, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 2, 10, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 3, 11, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 4, 12, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 5, 1, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 6, 2, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 7, 3, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 8, 4, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 9, 5, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 10, 6, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 11, 7, harvest_month_begin))%>%
  mutate(harvest_month_begin = if_else(country == "Ethiopia" & harvest_month_begin == 12, 8, harvest_month_begin))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 1, 9, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 2, 10, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 3, 11, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 4, 12, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 5, 1, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 6, 2, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 7, 3, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 8, 4, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 9, 5, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 10, 6, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 11, 7, harvest_month_end))%>%
  mutate(harvest_month_end = if_else(country == "Ethiopia" & harvest_month_end == 12, 8, harvest_month_end))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 1, 9, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 2, 10, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 3, 11, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 4, 12, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 5, 1, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 6, 2, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 7, 3, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 8, 4, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 9, 5, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 10, 6, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 11, 7, planting_month))%>%
  mutate(planting_month = if_else(country == "Ethiopia" & planting_month == 12, 8, planting_month))

############################### crop_area_share ############################### 
#crop_area_share set to a value between 0 and 100 otherwise NA
DATA <- DATA %>%
  mutate(crop_area_share = if_else(crop_area_share >= 0 & crop_area_share <= 100, crop_area_share, NA_integer_))
  
############################### dates ############################### 
# set years and months recorded as 0 to nan/ set years referencing the future (e.g., year 8000) to nan
# unrealisitische Jahre weg
# unrealistische Jahre in den Umfragen ausschließen
# wie bei eth 13 -> für jede studie zeitraum angeben (code)
#set planting/harvest months and years outside a predefined time window to NA
#(bitte die definierten Zeiträume in Tabelle 1 auflisten)

#NAs before 
na_before_hyb <- sum(is.na(DATA[["harvest_year_begin"]]))
na_before_hye <- sum(is.na(DATA[["harvest_year_end"]]))
na_before_hmb <- sum(is.na(DATA[["harvest_month_begin"]]))
na_before_hme <- sum(is.na(DATA[["harvest_month_end"]]))
na_before_py <- sum(is.na(DATA[["planting_year"]]))
na_before_pm <- sum(is.na(DATA[["planting_month"]]))

####################### UGA umrechnen - first try ##############

# subset_DATA <- DATA %>%
#   filter(country == "Uganda" & harvest_month_begin >= 13 & harvest_month_begin <= 24)
# unique(subset_DATA$dataset_name)
# subset_DATA <- DATA %>%
#   filter(country == "Uganda" & harvest_month_end >= 13 & harvest_month_end <= 24)
# unique(subset_DATA$dataset_name)
# subset_DATA <- DATA %>%
#   filter(country == "Uganda" & planting_month >= 13 & planting_month <= 24)
# unique(subset_DATA$dataset_name)
##### --> only 2015 UGA

#first try
# #dataframe mit den Daten für harvest_month begin
# df <- data.frame(
#   number = 1:27,
#   month_name = c(
#     1, 2, 3, 4, 5,
#     6, 7, 8, 9, 10,
#     11, 12, 1, 2,
#     3, 4, 5, 6, 7,
#     8, 9, 10, 11, 12,
#     1, 2, 3
#   ),
#   year = c(
#     rep(2014, 12), rep(2015, 12), rep(2016, 3)
#   )
# )
# 
# DATA_extended <- DATA %>%
#   left_join(df, by = c("harvest_month_begin" = "number"))


####################### UGA umrechnen - second try ##############

DATA <- DATA %>%
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

# # Remove the helper columns
DATA <- DATA %>%
  select(-condition_1, -condition_2, -condition_3, -condition_4, -condition_5)

subset_DATA <- DATA %>%
  filter(country == "Uganda" & harvest_month_begin >= 13 & harvest_month_begin <= 24)
unique(subset_DATA$dataset_name)

DATA <- DATA %>%
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

# # Remove the helper columns
DATA <- DATA %>%
  select(-condition_1, -condition_2, -condition_3, -condition_4, -condition_5)

subset_DATA <- DATA %>%
  filter(country == "Uganda" & harvest_month_end >= 13 & harvest_month_end <= 24)
unique(subset_DATA$dataset_name)

################################ xxxxxxxxxxxx #####################

#for simplicity of the join
data_collection_dates <- data_collection_dates %>%
  select (-dataset_name, -country)

DATA <- DATA %>%
  left_join(data_collection_dates, by = "dataset_doi")

################## New code - date correction ###############

#planting year

DATA <- DATA %>%
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
DATA <- DATA %>%
  select(-condition_1, -condition_2, -condition_3, -condition_4, -condition_5, -condition_6)


# harvest_year_begin
DATA <- DATA %>%
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

# # Remove the helper columns
DATA <- DATA %>%
  select(-condition_1, -condition_3, -condition_4, -condition_6)


# harvest_year_end
DATA <- DATA %>%
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
DATA <- DATA %>%
  select(-condition_1, -condition_4)

################### OLD CODE ############################
#check years if outside the range
# DATA <- DATA %>%
#   mutate(harvest_year = if_else(harvest_year > End_year | harvest_year < Begin_year, NA_real_, harvest_year)) %>%
#   mutate(harvest_year_begin = if_else(harvest_year_begin > End_year | harvest_year_begin < Begin_year, NA_real_, harvest_year_begin)) %>%
#   mutate(harvest_year_end = if_else(harvest_year_end > End_year | harvest_year_end < Begin_year, NA_real_, harvest_year_end))%>%
#   mutate(planting_year = if_else(planting_year > End_year | planting_year < 1900, NA_real_, planting_year))

###################################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!####################################
# #was, wenn harvest_year_end vor begin liegt
# filtered_df <- DATA %>%
#   filter(harvest_year_begin > harvest_year_end)
# 
# cat("Number of occurences where harvest_year_begin is greater than harvest_year_end is:", nrow(filtered_df), "\n")
# unique(filtered_df$dataset_name)
# 
# #was, wenn harvest_year_end gleich begin liegt, aber harvest_month_begin > harvest_month_end
# filtered_df_2 <- DATA %>%
#   filter(harvest_year_begin == harvest_year_end)%>%
#   filter(harvest_month_begin > harvest_month_end)
# 
# cat("Number of occurences where harvest_month_begin is later than harvest_month_end is:", nrow(filtered_df_2), "\n")
# unique(filtered_df_2$dataset_name)
# 
# #was, wenn planting_year vor harvest_year_begin liegt 
# filtered_df_3 <- DATA %>%
#   filter(planting_year > harvest_year_begin)
# 
# cat("Number of occurences where harvest_year_begin is before planting_year", nrow(filtered_df_3), "\n")
# unique(filtered_df_3$dataset_name)
# #nur UGA, außer 4 alle 2015
# 
# #was, wenn planting_year vor harvest_year_begin liegt 
# filtered_df_4 <- DATA %>%
#   filter(planting_year == harvest_year_begin)%>%
#   filter(harvest_month_begin < planting_month)
# 
# cat("Number of occurences where planting_month is after harvest_month_begin", nrow(filtered_df_4), "\n")
# unique(filtered_df_4$dataset_name)
# 
# filtered_df_5 <- DATA %>%
#   filter(planting_month > End_month & planting_year == End_year)
# cat("Number of occurences where planting date  is after End date of survey", nrow(filtered_df_5), "\n")
# unique(filtered_df_5$dataset_name)


###################################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!####################################

################### OLD CODE ########################

# #check the months in the years available
# #planting
# DATA <- DATA %>%
#   mutate(planting_month = if_else((planting_month > End_month & planting_year == End_year) | (planting_month < Begin_month & planting_year == Begin_year), NA_real_, planting_month),
#          planting_year = if_else((planting_month > End_month & planting_year == End_year) | (planting_month < Begin_month & planting_year == Begin_year), NA_real_, planting_year))
# 
# #harvest
# DATA <- DATA %>%
#   mutate(harvest_month_end = if_else((harvest_month_end > End_month & harvest_year_end == End_year), NA_real_, harvest_month_end),
#          harvest_year_end = if_else((harvest_month_end > End_month & harvest_year_end == End_year), NA_real_, harvest_year_end),
#          harvest_month_begin = if_else((harvest_month_begin < Begin_month & harvest_year_begin == Begin_year), NA_real_, harvest_month_begin),
#          harvest_year_begin = if_else((harvest_month_begin < Begin_month & harvest_year_begin == Begin_year), NA_real_, harvest_year_begin))

################## checking NA for dates################
#NAs after this
na_after_hyb <- sum(is.na(DATA[["harvest_year_begin"]]))
na_after_hye <- sum(is.na(DATA[["harvest_year_end"]]))
na_after_hmb <- sum(is.na(DATA[["harvest_month_begin"]]))
na_after_hme <- sum(is.na(DATA[["harvest_month_end"]]))
na_after_py <- sum(is.na(DATA[["planting_year"]]))
na_after_pm <- sum(is.na(DATA[["planting_month"]]))

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


# # set month >12 or <1 to nan
#
DATA <- DATA %>%
  mutate(harvest_month_begin = if_else(harvest_month_begin >= 1 & harvest_month_begin <= 12, harvest_month_begin, NA_integer_)) %>%
  mutate(harvest_month_end = if_else(harvest_month_end >= 1 & harvest_month_end <= 12, harvest_month_end, NA_integer_)) %>%
  mutate(harvest_month = if_else(harvest_month >= 1 & harvest_month <= 12, harvest_month, NA_integer_)) %>%
  mutate(planting_month = if_else(planting_month >= 1 & planting_month <= 12, planting_month, NA_integer_))

#after more months were excluded
#NAs after this
na_end_hmb <- sum(is.na(DATA[["harvest_month_begin"]]))
na_end_hme <- sum(is.na(DATA[["harvest_month_end"]]))
na_end_pm <- sum(is.na(DATA[["planting_month"]]))

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



# Remove the additional columns from the join
DATA <- DATA %>%
  select(-End_year, -End_month, -Begin_year , -Begin_month)

############################### Missing value identifier ############################### 
# set likely missing value identifiers for all variables to nan (99, 9999, 999999, 99.9999)
# 

# filere_df <- DATA %>%
#   filter(plot_area_reported_ha == 9900.0)
# 
# dataset_name_counts <- filere_df %>%
#   count(dataset_name)

DATA <- DATA %>%
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

############################### negative areas ############################### 
# set negative areas to nan (if any)


DATA <- DATA %>%
  mutate(plot_area_measured_ha=ifelse(plot_area_measured_ha < 0, NA, plot_area_measured_ha))

############################### lat & lon = 0 ############################### 
# set lat/lon 0/0 or nan/0 or 0/nan to missing
#
sum(is.na(DATA[["lon"]]))/nrow(DATA) * 100
sum(is.na(DATA[["lat"]]))/nrow(DATA) * 100

DATA <- DATA %>%
  mutate(lat = if_else(lat == 0 & lon == 0, NA_real_, lat),
         lon = if_else(lat == 0 & lon == 0, NA_real_, lon))

#NA_percentage
na_lon <- sum(is.na(DATA[["lon"]]))/nrow(DATA) * 100
na_lat <- sum(is.na(DATA[["lat"]]))/nrow(DATA) * 100
# na_lon
# na_lat

print("NA percentage of lon and lat")
sum(is.na(DATA[["lon"]]))/nrow(DATA) * 100
sum(is.na(DATA[["lat"]]))/nrow(DATA) * 100

# first adm then NA
print("percentage of lat-NAs with adm3 values")
filtered_df <- DATA[!is.na(DATA[["adm3"]]), ]
sum(is.na(filtered_df[["lat"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm4 values")
filtered_df <- DATA[!is.na(DATA[["adm4"]]), ]
sum(is.na(filtered_df[["lat"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm2 values")
filtered_df <- DATA[!is.na(DATA[["adm2"]]), ]
sum(is.na(filtered_df[["lat"]])) / nrow(filtered_df)*100

#first NA, then adm
print("percentage of lat-NAs with adm2 values")
filtered_df <- DATA[is.na(DATA[["lat"]]), ]
sum(!is.na(filtered_df[["adm2"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm3 values")
sum(!is.na(filtered_df[["adm3"]])) / nrow(filtered_df)*100
print("percentage of lat-NAs with adm4 values")
sum(!is.na(filtered_df[["adm4"]])) / nrow(filtered_df)*100

## adm3 = NA, but not adm4
filtered_df <- DATA[is.na(DATA[["adm3"]]) & !is.na(DATA[["adm4"]]), ]
nrow(filtered_df)
# -> only in UGA 2011


############################### seasons ############################### 
# remove season variable for now, too inconsistent and not always reported from individual countries
# as an alternative we can try to harmonize season values 
DATA <- DATA %>% select(-season)

############################### localUnit_area ############################### 
DATA <- mutate(DATA, localUnit_area = tolower(localUnit_area))
DATA <- DATA %>% 
  mutate (localUnit_area = case_when(
    localUnit_area %in% c("acres", "acre") ~ "acres",
    localUnit_area %in% c("square metre", "square metres", "square meters") ~ "square metres",
    localUnit_area %in% c("other", "other \\(specify\\)") ~ "other",
    localUnit_area %in% c("hectare", "hectares") ~ "hectares",
    localUnit_area %in% c(".a", "0") ~ NA_character_,
    grepl("rope\\(gemed\\)", localUnit_area) ~ "rope (gemed)",
    TRUE ~ localUnit_area
  ))
unique(sort(DATA$localUnit_area))

############################### adm4 in Nigeria & GPS levels ############################### 
# Set all values of 'adm4' to NA where 'country' is "Nigeria"
DATA$adm4[DATA$country == "Nigeria"] <- NA

# > unique(DATA$GPS_level)
# [1] "3.0"       NA          "3"         "EA"        "Household"

# filere_df <- DATA %>%
#   filter(GPS_level == "Household")
# 
# dataset_name_counts <- filere_df %>%
#   count(dataset_name)
# 
# filtered_df <- DATA %>%
#   filter(dataset_name == "UGA_2011_UNPS_v01_M")

DATA <- DATA %>%
  mutate(GPS_level = case_when(
    GPS_level == "3.0" ~ "3",
    GPS_level == "3" ~ "3",
    GPS_level == "Household" ~ "2",
    GPS_level == "EA" ~ "3"
  ))

# count_occurrences <- DATA %>%
#   filter(!is.na(lat) & !is.na(lon) & is.na(GPS_level)) %>%
#   summarise(count = n())
filtered_DATA <- DATA %>%
  filter(!is.na(lat) & !is.na(lon) & is.na(GPS_level))
unique(filtered_DATA$dataset_name)

# Set all values of 'adm4' to NA where 'country' is "Nigeria"
# DATA$GPS_level[DATA$country == "Nigeria"] <- NA
# DATA$GPS_level <- as.character(DATA$GPS_level)
DATA <- DATA %>%
  mutate(GPS_level = if_else(country == "Nigeria" & !is.na(lat) & !is.na(lon), "4", GPS_level))


############################### columns without observations ############################### 


#remove columns without any values:
#
DATA <- DATA %>%
  select(where(~!all(is.na(.))))


DATA <- DATA %>%
  filter(!(is.na(crop) & is.na(crop_area_share) & is.na(planting_month) & is.na(planting_year) & is.na(harvest_month_begin)& is.na(harvest_month_end)& is.na(plot_area_reported_localUnit)& is.na(localUnit_area)& is.na(plot_area_measured_ha)& is.na(harvest_year_end)& is.na(plot_area_reported_ha)& is.na(harvest_year_begin)))
DATA_filtered_2 <- DATA %>%
  filter(is.na(crop) & is.na(crop_area_share) & is.na(planting_month) & is.na(planting_year) & is.na(harvest_month_begin)& is.na(harvest_month_end)& is.na(plot_area_reported_localUnit)& is.na(localUnit_area)& is.na(plot_area_measured_ha)& is.na(harvest_year_end)& is.na(plot_area_reported_ha)& is.na(harvest_year_begin))


############################### mwi  AND ner dataset names ############################### 
DATA <- DATA %>%
  mutate(dataset_name = case_when(
    dataset_name == "mwi_2010_ihs-iii_v01_m" ~ "MWI_2010_IHS-III_v01_M",
    dataset_name == "mwi_2010-2013_ihps_v01_m" ~ "MWI_2010-2013_IHPS_v01_M",
    dataset_name == "mwi_2016_ihs-iv_v04_m" ~ "MWI_2016_IHS-IV_v04_M",
    dataset_name == "mwi_2019_ihs-v_v05_m" ~ "MWI_2019_IHS-V_v05_M",
    dataset_name == "NER_2011_ECVMA_V01_M" ~ "NER_2011_ECVMA_v01_M",
    TRUE ~ dataset_name  # Keep other values unchanged
  ))


unique(DATA$dataset_name)

############################### lat & lon for countries without data ############################### 
#not yet:
# set lat/lon to missing if referencing datapoints far away from the reference country (but not if just outside of reference country; e.g. in Malawi, a larger number of datapoints was collected from just across the border when using FAO-GAUL boundaries, but we should not judge where a country ends or exclude data when its genuinely referencing a location just outside a country)

############################### rows without crops: deleted ############################### 

DATA <- DATA %>% filter(!is.na(crop))

############################### output ############################### 

AFTER <- ff_glimpse (DATA)

CONT_AFTER <- AFTER$Continuous
CAT_AFTER <- AFTER$Categorical
# 
# 
# CONT_BEFORE[3:12] <- lapply(CONT_BEFORE[3:12], as.numeric)
# CONT_AFTER[3:12] <- lapply(CONT_AFTER[3:12], as.numeric)
# Difference <- CONT_BEFORE[,3:12] - CONT_AFTER[,3:12]

write_csv(DATA, "PostProcess/postprocessed_data.csv")

