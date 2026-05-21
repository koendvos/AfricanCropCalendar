# AfricanCropCalendar

This repository generates a database of planting and harvest dates from LSMS-ISA surveys for the six countries: Ethiopia, Malawi, Mali, Niger, Nigeria, and Uganda. The project consists of extracting raw survey data, converting it into a harmonized format, and integrating it into a unique database. Burkina Faso and Tanzania were removed after initial data exploration showed that planting and harvest date information cannot be extracted.

The final dataset can be found [here](AfricanCropCalendar.csv), or downloaded through [Figshare](https://figshare.com/articles/dataset/AfricanCropCalendar_A_geo-referenced_dataset_of_crop_growing_seasons_across_diverse_agro-ecological_regions_in_Sub-Saharan_Africa_/28659557)
Cite as:
Katharina Waha, Sophie Rötzer, Koen De Vos, Uwe Grewer, Altaaf Mechiche-Alami, Andrew Tomes (2026): African Crop Calendar: A geo-referenced dataset of crop growing seasons across diverse agro-ecological regions. Scientific Data. (to update)

Raw data per country should be downloaded from the dedicated raw databases. Scripts to process and harmonize the data can be found in the dedicated country folders: [Ethiopia](ETH), [Mali](MLI), [Malawi](MWI), [Niger](NER), [Nigeria](NGA), and [Uganda](UGA)

Harmonized files and metadata per country can be found in [out](out) per survey wave.

Scripts and additional checks performed to integrate the individual countries into a single database can be found in [PostProcess](PostProcess)

Further information on the LSMS-ISA surveys can be found [here](https://www.worldbank.org/en/programs/lsms/initiatives/lsms-ISA)
