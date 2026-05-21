# Uganda (UGA) Processing

## Description
This provides a detailed overview of the processing done for Uganda using the UNPS (Uganda National Panel Survey) data across multiple survey waves.
The raw data can be downloaded from:
[Wave 1](https://microdata.worldbank.org/index.php/catalog/2059)
[Wave 2](https://microdata.worldbank.org/index.php/catalog/2663)
[Wave 3](https://microdata.worldbank.org/index.php/catalog/3460)
[Wave 4](https://microdata.worldbank.org/index.php/catalog/3795)
[Wave 5](https://microdata.worldbank.org/index.php/catalog/3902)


## Main Entry Point
The main R scripts for executing the multi-cropping model are located at:
- `/UGA/UgandaMulti11.R` - Processes Wave 1 survey data
- `/UGA/UgandaMulti13.R` - Processes Wave 2 survey data
- `/UGA/UgandaMulti15.R` - Processes Wave 3 survey data
- `/UGA/UgandaMulti18.R` - Processes Wave 4 survey data
- `/UGA/UgandaMulti19.R` - Processes Wave 5 survey data
- `/UGA/UGA_create_allwaves.R` - Consolidates all waves into a unified output

These scripts provide the processing for the different waves in Uganda.

## Contents
- **UgandaMulti11.R**: Processing script for Wave 1 (first wave) survey data
- **UgandaMulti13.R**: Processing script for Wave 2 (second wave) survey data
- **UgandaMulti15.R**: Processing script for Wave 3 (third wave) survey data
- **UgandaMulti18.R**: Processing script for Wave 4 (fourth wave) survey data
- **UgandaMulti19.R**: Processing script for Wave 5 (fifth wave) survey data
- **UGA_create_allwaves.R**: Consolidation script that merges all waves
- **UGA_metadatafile_15.R**: Metadata generation script for Wave 3
- **UGA_metadatafile_18.R**: Metadata generation script for Wave 4
- **UGA_metadatafile_19.R**: Metadata generation script for Wave 5
- **Crop_Code.csv**: Crop code mapping file

## Scripts Overview

### Wave-Specific Scripts
Each wave-specific script processes UNPS survey data and:
- Extracts household information and GPS coordinates
- Handles first and second visit data related to agricultural seasons
- Merges planting and harvesting information
- Creates seasonal identifiers to standardize data across agricultural seasons
- Converts plot areas from acres to hectares
- Generates harmonized CSV output with administrative divisions, household/plot identifiers, crop information, planting/harvest dates, and plot areas

### Consolidation Script
The `UGA_create_allwaves.R` script:
- Consolidates all waves and associated metadata files into single output files
- Facilitates cross-country merging of data
- Ensures uniformity and compatibility for further analysis

## Usage
1. Clone the repository:  
   `git clone https://github.com/koendvos/AfricanCropCalendar.git`  
2. Change directory:  
   `cd AfricanCropCalendar/UGA`  
3. Ensure UNPS data files are properly located
4. Run the wave-specific scripts in sequence:  
   `Rscript UgandaMulti11.R`  
   `Rscript UgandaMulti13.R`  
   `Rscript UgandaMulti15.R`  
   `Rscript UgandaMulti18.R`  
   `Rscript UgandaMulti19.R`  
5. Run the consolidation script:  
   `Rscript UGA_create_allwaves.R`

### Note
Ensure to check file paths and required input data formats when using the scripts. Each script is designed to handle specific versions of the UNPS survey data. Verify output correctness and completeness after execution.