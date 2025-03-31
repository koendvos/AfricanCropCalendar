clear

version 18


*******************************************************************
*******************************************************************
* When exporting ag_mod_d of survey wave 2019 for Malawi
* the variable "ag_d21" (soil type) is for various rows incorrectly split into two cells.
* Some rows are consequentially shifted by one cell towards the right.
* Here, the problematic column is deleted prior to exporting from dta to csv.
*******************************************************************
*******************************************************************

// define locals of project- and data-path
local project_path "/datadisk2/Scientific/Study_PhD/07_papers/LSMS_cropSeasons"
local data_path "`project_path'/LSMS_MWI_raw"

// set working directory
cd "`data_path'"
pwd

// specify logfile
log using "manualCSVexport_2019_ag_mod_d_LOGFILE", replace


// cd to folder of input dta-files
cd "`project_path'/LSMS_MWI_raw/2019_2020/MWI_2019_IHS-V_v05_M_Stata"


// load Stata dta-file
use ag_mod_d.dta

// drop malformatted variable (Predominant Soil Type on Plot )
drop ag_d21

// export dataset
export delimited using "`project_path'/LSMS_MWI_raw/2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport/ag_mod_d_modified.csv", replace

// *** Not needed: labels are exported correctly in standard loop (and are more complete with keeping label for ag_d21)
// *export variable names and lables
// preserve
//   describe, replace clear
//   list
//   export delimited using "`project_path'/LSMS_MWI_raw/2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport/ag_mod_d_modified_labels.csv", replace
// restore



exit, clear STATA
