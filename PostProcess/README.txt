Author/contact information: Sophie Rötzer, Uwe Grewer, Katharina Waha
katharina.waha@uni-a.de

Instructions to run post_processing.R

This file merges the individual country and survey data files from the /out folder 
and then inspects and cleans them to create a harmonized dataset.

There a couple of helper objects to check what happens during the cleaning and 
harmonization process:

CAT_BEFORE & CONT_BEFORE: initial descriptive statistics and number of missing values for categorical and continuous variables

CAT_AFTER & CONT_AFTER: descriptive statistics and number of missing values for categorical and continuous variables after cleaning

To check how many NAs were introduced after first step of cleaning: set years and months recorded as 0 to na, 
set years referencing the future (e.g., year 8000) to na, no planting dates after the harvest dates, no planting or harvesting years before 1900, no planting and harvest year after end of the survey.

na_after/before/difference_hmb: NA statistics for harvest month begin
na_after/before/difference_hme: NA statistics for harvest month end
na_after/before/difference_hyb: NA statistics for harvest year begin
na_after/before/difference_pm: NA statistics for planting month
na_after/before/difference_py: NA statistics for plan ting year

To check how many NAs were introduced after second step of cleaning: set harvest and planting dates to NA if not within a range of 1 to 12.

na_end_hmb: NA statistics for harvest month begin 
na_end_hme: NA statistics for harvest month end
na_end_pm: NA statistics for planting month

Output

PostProcess/postprocessed_data.csv