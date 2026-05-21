Ethiopia ESS Waves 1-4 Crop Calendar Data Preparation

* Data Sources
  * Raw data used in this project are available on the World Bank's web site at [ESS Wave 1](https://microdata.worldbank.org/index.php/catalog/2053), [ESS Wave 2](https://microdata.worldbank.org/index.php/catalog/2247), [ESS Wave 3](https://microdata.worldbank.org/index.php/catalog/2783), and [ESS Wave 4](https://microdata.worldbank.org/index.php/catalog/3823).
* Execution
  * Code files can be executed using the R programming language, obtainable from https://www.r-project.org/. Make sure to update any file paths that appear in the code to match your system.
* Outputs
  * Script outputs are located in the "out" folder of this repository. See the metadata files for information on the variables.
* Data Processing Steps
  1. Household geolocation information (administrative units and coordinates) is obtained from the household roster and the supplemental geodata file.
  2. Relevant crop production variables are imported from the post-planting and post-harvest agricultural rosters and renamed.
  3. Nonstandard area units of measure are converted to hectares.
  4. Planting/harvest dates are recorded from the survey responses and converted from the Ethiopian calendar to Gregorian.
  5. The data are combined into a single table, aligned with the metadata, and saved to the output file.
  6. The script "ETH_allwaves.R" combines all four wave files into a single table.
