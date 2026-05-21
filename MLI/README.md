# Mali (MLI) Processing

## Data Sources
  * Raw data used in this project are available on the World Bank's web site at [Wave 1: 2014-2015](https://microdata.worldbank.org/catalog/2583), and [Wave 2: 2017-2018](https://microdata.worldbank.org/catalog/4295).

## Description
This provides a detailed overview of the processing done for Mali
## Main Entry Point
The main R scripts for executing the multi-cropping model is located at `/scripts/Mali_MultiCropping.R`. This script provides the processing for Mali. 

## Contents
- **/data/**: Directory containing source datasets, note that this folder does not contain raw datasets from LSMS study. 
- **/metadata**: Directory containing generated metadata
- **/out**: Directory containing the harmonized files for Mali.
- **/scripts/**: Directory containing the script used for multi-cropping analysis.

## Usage
1. Clone the repository:  
   `git clone https://github.com/koendvos/AfricanCropCalendar.git`  
2. Change directory:  
   `cd AfricanCropCalendar`  
3. Run the main script:  
   `Rscript scripts/Mali_MultiCropping.R`
