Nigeria GHS Waves 3 - 5 Crop Calendar Data Preparation
* Source
  * This code is based on the Evans Policy Analysis and Research (EPAR) LSMS-ISA indicator curation project. Learn more at https://github.com/EvansSchoolPolicyAnalysisAndResearch/LSMS-Agricultural-Indicators-Code 
* Data Sources
  * Raw data used in this project are included in the raw data subfolders. The full datasets are available from the World Bank's website; [GHS W3](https://microdata.worldbank.org/index.php/catalog/2734), [GHS W4](https://microdata.worldbank.org/index.php/catalog/3557), [GHS W5](https://microdata.worldbank.org/index.php/catalog/6410).
* Execution
  * The code files can be executed using [Stata](https://www.stata.com/). Update paths in the files as needed using the global macros in the header.
* Outputs
  * Script outputs are available in the "results" csv file. See the metadata files for information on the variables.
* Data Processing Steps
  1. Weights are recalculated to counteract the effect of sample attrition on national-level estimates. The existing survey weights are readjusted so that population totals derived from the dataset match the rural and urban populations estimated by the world bank for the year of the survey wave.
  2. Coordinates, representing the centroid of all households in a sampled enumeration area (EA), are recorded from the geocoordinates raw data file. Households that relocated between surveys have a recorded EA code of 0. This value is converted to the text label "moved." 
  3. Plot areas are drawn from the GPS area measurements taken at the time of the survey. In cases where measurement was not available, respondent estimates are converted from local units where necessary using conversion factors provided in the GHS Wave 1 basic information document (BID).
  4. The gender of the person responsible for making decisions on each plot (reported as "mixed" if there are multiple of different genders) is determined from survey responses.
  5. Areas planted and harvested are calculated for each crop. Areas were provided as either percentage of the field (area planted) or percentage of area planted (area harvested) supplemented by direct estimates. We use percentages to produce estimates first, using respondent estimation when they were omitted. Contradictions between area planted/harvested and plot area result from estimation/conversion uncertainties or overreporting. These contradictions are resolved by dividing the area planted/harvested for each crop and dividing by the total reported area planted/harvested and then multiplying by the recorded plot area.
  6. Planting month/year for each crop are recorded based on survey responses. Harvest is recorded with a beginning date and an end date and are also recorded directly from survey responses.
  7. Variables are aligned with the metadata and saved to the output file.
