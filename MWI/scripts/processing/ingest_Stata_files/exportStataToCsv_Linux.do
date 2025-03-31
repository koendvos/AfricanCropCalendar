clear
version 18


*******************************************************************
*******************************************************************


***** define path to project folder *****
local path "/datadisk2/Scientific/Study_PhD/07_papers/LSMS_cropSeasons"

***** set parent-foler as working directory *****
display "`path'"
cd "`path'"
pwd

***** define log-file *****
log using "exportStataToCsv_Linux_LOGFILE", replace


// if confirmdir is not yet installed, run: ssc install confirmdir


**************************************************************************************************************************************
**************************************************************************************************************************************
**************************************************************************************************************************************
**************************************************************************************************************************************

*******************************************************************
*******************************************************************

***** Country & survey wave: *****
***** Malawi 2004_2005 *****
// cd to folder of input dta-files
cd "`path'/LSMS_MWI_raw/2004_2005/MWI_2004_IHS-II_v01_M_Stata8"

// Create local of output folder path
loc newplace "`path'/LSMS_MWI_raw/2004_2005/MWI_2004_IHS-II_v01_M_Stata8_DtaToCsvExport"

*******************************************************************
// Create the directory of output files (if not yet existant)
confirmdir "`newplace'"
di _rc
if `r(confirmdir)'==170 {
		mkdir "`newplace'"
		display in yellow "Project directory named: `newplace' created"
		}
else disp as error "`newplace' already exists, not created."


// get a list of all Stata files in the input-directory
loc datasets : dir . files "*.dta"

// loop over each dataset
foreach f of local datasets {
    di as result "Reading `f'"
    use "`f'", clear

	*export dataset
	export delimited using "`newplace'/`f'.csv", replace

	*export variable names and lables
	preserve
		describe, replace
		list
		export delimited using "`newplace'/`f'_labels.csv", replace
	restore
}



*******************************************************************
*******************************************************************

***** Country & survey wave: *****
***** Malawi 2010_2011 *****
// cd to folder of input dta-files
cd "`path'/LSMS_MWI_raw/2010_2011/MWI_2010_IHS-III_v01_M_STATA8"

// Create local of output folder path
loc newplace "`path'/LSMS_MWI_raw/2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport"

*******************************************************************
// Create the directory of output files (if not yet existant)
confirmdir "`newplace'"
di _rc
if `r(confirmdir)'==170 {
		mkdir "`newplace'"
		display in yellow "Project directory named: `newplace' created"
		}
else disp as error "`newplace' already exists, not created."


// get a list of all Stata files in the input-directory
loc datasets : dir . files "*.dta"

// loop over each dataset
foreach f of local datasets {
    di as result "Reading `f'"
    use "`f'", clear

	*export dataset
	export delimited using "`newplace'/`f'.csv", replace

	*export variable names and lables
	preserve
		describe, replace
		list
		export delimited using "`newplace'/`f'_labels.csv", replace
	restore
}



*******************************************************************
*******************************************************************

***** Country & survey wave: *****
***** Malawi 2010_2013_shortTermPanel *****
// cd to folder of input dta-files
cd "`path'/LSMS_MWI_raw/2010_2013_shortTermPanel/MWI_2010-2013_IHPS_v01_M_Stata"

// Create local of output folder path
loc newplace "`path'/LSMS_MWI_raw/2010_2013_shortTermPanel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport"

*******************************************************************
// Create the directory of output files (if not yet existant)
confirmdir "`newplace'"
di _rc
if `r(confirmdir)'==170 {
		mkdir "`newplace'"
		display in yellow "Project directory named: `newplace' created"
		}
else disp as error "`newplace' already exists, not created."


// get a list of all Stata files in the input-directory
loc datasets : dir . files "*.dta"

// loop over each dataset
foreach f of local datasets {
    di as result "Reading `f'"
    use "`f'", clear

	*export dataset
	export delimited using "`newplace'/`f'.csv", replace

	*export variable names and lables
	preserve
		describe, replace
		list
		export delimited using "`newplace'/`f'_labels.csv", replace
	restore
}





*******************************************************************
*******************************************************************

***** Country & survey wave: *****
***** Malawi 2016_2017 *****
// cd to folder of input dta-files
cd "`path'/LSMS_MWI_raw/2016_2017/MWI_2016_IHS-IV_v04_M_STATA14"

// Create local of output folder path
loc newplace "`path'/LSMS_MWI_raw/2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport"

*******************************************************************
// Create the directory of output files (if not yet existant)
confirmdir "`newplace'"
di _rc
if `r(confirmdir)'==170 {
		mkdir "`newplace'"
		display in yellow "Project directory named: `newplace' created"
		}
else disp as error "`newplace' already exists, not created."


// get a list of all Stata files in the input-directory
loc datasets : dir . files "*.dta"

// loop over each dataset
foreach f of local datasets {
    di as result "Reading `f'"
    use "`f'", clear

	*export dataset
	export delimited using "`newplace'/`f'.csv", replace

	*export variable names and lables
	preserve
		describe, replace
		list
		export delimited using "`newplace'/`f'_labels.csv", replace
	restore
}


*******************************************************************
*******************************************************************

***** Country & survey wave: *****
***** Malawi 2019_2020 *****
// cd to folder of input dta-files
cd "`path'/LSMS_MWI_raw/2019_2020/MWI_2019_IHS-V_v05_M_Stata"


// Create local of output folder path
loc newplace "`path'/LSMS_MWI_raw/2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport"

*******************************************************************
// Create the directory of output files (if not yet existant)
confirmdir "`newplace'"
di _rc
if `r(confirmdir)'==170 {
		mkdir "`newplace'"
		display in yellow "Project directory named: `newplace' created"
		}
else disp as error "`newplace' already exists, not created."


// get a list of all Stata files in the input-directory
loc datasets : dir . files "*.dta"

// loop over each dataset
foreach f of local datasets {
    di as result "Reading `f'"
    use "`f'", clear

	*export dataset
	export delimited using "`newplace'/`f'.csv", replace

	*export variable names and lables
	preserve
		describe, replace
		list
		export delimited using "`newplace'/`f'_labels.csv", replace
	restore
}






**************************************************************************************************************************************
**************************************************************************************************************************************
**************************************************************************************************************************************
**************************************************************************************************************************************


log close
*exit,clear
exit, STATA clear
