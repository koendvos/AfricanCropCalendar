# Niger (NER) Processing

## Description
This provides a detailed overview of the multi-cropping system in Niger, highlighting the specific crops, seasonality, and local agricultural practices. It serves as a guideline for farmers and agricultural enthusiasts.

Data can be downloaded from:
[Wave 1](https://microdata.worldbank.org/index.php/catalog/2050)
[Wave 2](https://microdata.worldbank.org/index.php/catalog/2676)

## Main Entry Point
The main R scripts for executing the multi-cropping model is located at `/scripts/Niger_MultiCropping.R` and `/scripts/Niger_bis11.R`. These scripts provide the processing for Wave 1 and Wave 2. Make sure to update the file paths in the R scripts to match that of your system. 

## Contents
- **/data/**: Directory containing source datasets, make sure to store the data here. 
- **/metadata**: Directory containing generated metadata
- **/out**: Directory containing the harmonized files for Niger.
- **/scripts/**: Directory containing the scripts used multi-cropping analysis.

## Usage
1. Clone the repository:  
   `git clone https://github.com/koendvos/AfricanCropCalendar.git`  
2. Change directory:  
   `cd AfricanCropCalendar`  
3. Run the main scripts:  
   Wave 1: `Rscript scripts/Niger_MultiCropping.R` 
   Wave 2: `Rscript scripts/Niger11Bis.R`
