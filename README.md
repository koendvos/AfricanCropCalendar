# AfricanCropCalendar

This repository generates a database of planting and harvest dates from LSMS-ISA surveys for the six countries: Ethiopia, Malawi, Mali, Niger, Nigeria, and Uganda. The project consists of extracting raw survey data, converting it into a harmonized format, and integrating it into a unique database. Burkina Faso and Tanzania were removed after initial data exploration showed that planting and harvest date information cannot be extracted.

The final dataset can be found in this home folder:
AfricanCropCalendar_data.csv


Raw data per country and the code used to extract the required variables can be found in the dedicated country folders: Ethiopia (ETH), Mali (MLI), Malawi (MWI), Niger (NER), Nigeria (NGA), and Uganda (UGA).

Harmonized files and metadata per country can be found in the /out folder per survey wave.

Scripts and additional checks performed to integrate the individual countries into a single database can be found in the /PostProcess folder.
