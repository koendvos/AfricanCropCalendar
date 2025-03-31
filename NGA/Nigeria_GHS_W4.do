
clear
clear matrix
clear mata
program drop _all
set more off
set maxvar 10000


*Set location of raw data and output
global directory			"\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\RA Working Folders\Andrew\GitHub Dirs\LSMS_multiplecropping/NGA"

//set directories
*Nigeria General HH survey (NG LSMS)  Wave 4

global Nigeria_GHS_W4_raw_data			"${directory}/rawData-wave4"
global Nigeria_GHS_W4_created_data 		"\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\RA Working Folders\Andrew\CSIRO Data Request\Final DTA Files - CSIRO"

global Nigeria_GHS_W4_pop_tot 195874740
global Nigeria_GHS_W4_pop_rur 97263561
global Nigeria_GHS_W4_pop_urb 98611179

********************************************************************************
* WEIGHTS *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}\secta_plantingw4.dta", clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
drop if weight==.  //287 hh as expected
save  "${Nigeria_GHS_W4_created_data}\Nigeria_GHS_W4_weights.dta", replace


********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/secta_plantingw4.dta", clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
*DYA.11.21.2020 from the the BID
*"The final sample consisted of 4,976 households of which 1,425 were from the long panel sample and 3,551 from the refresh sample."
*Now sure why we have 5,263 obs in this file.
*It seems that Overall, 34 refresh EAs were inaccessible during the listing period or post-planting visit. 
*The EAs were highly concentrated in the North East and North Central Zones where conflict (insurgency and farmer-herder attacks) were prevalent during this period.
*But these likely show up this this file explaing why with have 287 a additional households.
duplicates report hhid
merge 1:1 hhid using  "${Nigeria_GHS_W4_created_data}\Nigeria_GHS_W4_weights.dta", keep(2 3) nogen  // keeping hh surveyed
save  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", replace



//ALT: This rescales the weights to match the population better (original weights underestimate total population and overestimate rural population)
********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}\sect1_plantingw4.dta", clear
gen hh_members = 1 if s1q4==1
replace hh_members = 1 if s1q3 != .
keep if hh_members==1 //Drop individuals who've left household
ren s1q2 gender
gen fhh = s1q3==1 & gender==2
collapse (sum) hh_members (max) fhh, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep(2 3)
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W4_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W4_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W4_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", replace

********************************************************************************
*GPS COORDINATES *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}\nga_householdgeovars_y4.dta", clear
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep(3) 
ren lat_dd_mod latitude
ren lon_dd_mod longitude
//ALT: Per the BID, coordinates are supposed to represent the ea centroid, so I'm not sure why there are multiple (sometimes substantially different) sets of coordinates for some eas.
keep hhid latitude longitude
gen GPS_level = "adm4"
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_coords.dta", replace


********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
use "${Nigeria_GHS_W4_raw_data}/sect11a1_plantingw4.dta", clear
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/sect11b1_plantingw4.dta", nogen
merge 1:1 hhid plotid using "${Nigeria_GHS_W4_raw_data}/secta1_harvestw4.dta", gen(plot_merge)
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep( 3)
ren s11aq4aa area_size
ren s11aq4b area_unit
ren sa1q11 area_size2 //GPS measurement, no units in file
ren s11aq4c area_meas_sqm
gen cultivate = s11b1q27 ==1 
*assuming new plots are cultivated
//replace cultivate = 1 if sa1q1aa==1
//replace cultivate = 1 if sa1q3==1 //ALT: This has changed to respondent ID for w4
*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Wave 3 unavailable, but Waves 1 & 2 are identical) 
*found at http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTRESEARCH/EXTLSMS/0,,contentMDK:23635560~pagePK:64168445~piPK:64168309~theSitePK:3358997,00.html
*General Conversion Factors to Hectares
//		Zone   Unit         Conversion Factor
//		All    Plots        0.0667
//		All    Acres        0.4
//		All    Hectares     1
//		All    Sq Meters    0.0001

*Zone Specific Conversion Factors to Hectares
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00012 	0.0027 		0.00006
//		2 		 0.00016 	0.004 		0.00016
//		3 		 0.00011 	0.00494 	0.00004
//		4 		 0.00019 	0.0023 		0.00004
//		5 		 0.00021 	0.0023 		0.00013
//		6  		 0.00012 	0.00001 	0.00041

//ALT observed from the data
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00281 	0.0059 		0.00121
//		2 		 0.00748 	0.0052 		0.0006
//		3 		 0.00787 	0.0051	 	0.0002
//		4 		 0.00003 	0.0010 		0.0003
//		5 		 0.00076 	0.0008 		0.009
//		6  		 0.00437 	0.0005	 	0.002
//ALT: See previous communications for issues associated with these conversion factors; they should not be considered accurate for W4.
*farmer reported field size for post-planting
gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters

replace field_size = area_size*0.00012 if area_unit==1 & zone==1						//reported in heaps
replace field_size = area_size*0.00016 if area_unit==1 & zone==2
replace field_size = area_size*0.00011 if area_unit==1 & zone==3
replace field_size = area_size*0.00019 if area_unit==1 & zone==4
replace field_size = area_size*0.00021 if area_unit==1 & zone==5
replace field_size = area_size*0.00012 if area_unit==1 & zone==6

replace field_size = area_size*0.0027 if area_unit==2 & zone==1							//reported in ridges
replace field_size = area_size*0.004 if area_unit==2 & zone==2
replace field_size = area_size*0.00494 if area_unit==2 & zone==3
replace field_size = area_size*0.0023 if area_unit==2 & zone==4
replace field_size = area_size*0.0023 if area_unit==2 & zone==5
replace field_size = area_size*0.00001 if area_unit==2 & zone==6

replace field_size = area_size*0.00006 if area_unit==3 & zone==1						//reported in stands
replace field_size = area_size*0.00016 if area_unit==3 & zone==2
replace field_size = area_size*0.00004 if area_unit==3 & zone==3
replace field_size = area_size*0.00004 if area_unit==3 & zone==4
replace field_size = area_size*0.00013 if area_unit==3 & zone==5
replace field_size = area_size*0.00041 if area_unit==3 & zone==6

/*ALT 02.23.23*/ gen plot_area_reported_ha = field_size
decode area_unit, g(localUnit_area)
replace localUnit_area = substr(localUnit_area, (strpos(localUnit_area, ".")+2), .)
ren area_size plot_area_reported_localUnit
*replacing farmer reported with GPS if available
replace field_size = area_meas_sqm*0.0001 if area_meas_sqm!=.   
gen gps_meas = (area_meas_sqm!=.)
ren area_meas_sqm plot_area_measured_ha
replace plot_area_measured_ha = plot_area_measured_ha/10000
la var plot_area_measured_ha "GPS-measured plot area, hectares"
la var gps_meas "Plot was measured with GPS, 1=Yes"
ren plotid plot_id


save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_areas.dta", replace

//ALT: Gender of plot decisionmaker - worth including to see if there are gender-based differences in planting timing?
********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************
*Creating gender variables for plot manager from post-planting
use "${Nigeria_GHS_W4_raw_data}/sect1_plantingw4.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep( 3)
gen female = s1q2==2 if s1q2!=.
gen age = s1q6
*dropping duplicates (data is at holder level so some individuals are listed multiple times, we only need one record for each) //ALT: No duplicates in this wave
duplicates drop hhid indiv, force
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_gender_merge_temp.dta", replace

*adding in gender variables for plot manager from post-harvest
use "${Nigeria_GHS_W4_raw_data}/sect1_harvestw4.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep( 3)
gen female = s1q2==2 if s1q2!=.
gen age = s1q4
duplicates drop hhid indiv, force
merge 1:1 hhid indiv using "$Nigeria_GHS_W4_created_data/Nigeria_GHS_W4_gender_merge_temp.dta", nogen 		
keep hhid indiv female age
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_gender_merge.dta", replace

*Using planting data 	
use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_areas.dta", clear 	
//Post-Planting
*First manager 
gen indiv = s11aq6a
merge m:1 hhid indiv using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_gender_merge_temp.dta", gen(dm1_merge) keep(1 3) 
gen dm1_female = female if s11aq6a!=.
drop indiv 
*Second manager 
gen indiv = s11aq6b
merge m:1 hhid indiv using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_gender_merge_temp.dta", gen(dm2_merge) keep(1 3)			
gen dm2_female = female & s11aq6b!=.
drop indiv 
//Post-Harvest (only reported for "new" plot)
*First manager 
gen indiv = sa1q2 
merge m:1 hhid indiv using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_gender_merge_temp.dta", gen(dm4_merge) keep(1 3)			
gen dm3_female = female & sa1q2!=.
drop indiv 
*Second manager 
gen indiv = sa1q2c_1
merge m:1 hhid indiv using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_gender_merge_temp.dta", gen(dm5_merge) keep(1 3)			
gen dm4_female = female & sa1q2c_1!=.
drop indiv 
*Replace PP with PH if missing
replace dm1_female=dm3_female if dm1_female==.
replace dm2_female=dm4_female if dm1_female==.
*Constructing three-part gendered decision-maker variable; male only (=1) female only (=2) or mixed (=3)
gen dm_gender = 1 if (dm1_female==0 | dm1_female==.) & (dm2_female==0 | dm2_female==.) & !(dm1_female==. & dm2_female==.)
replace dm_gender = 2 if (dm1_female==1 | dm1_female==.) & (dm2_female==1 | dm2_female==.) & !(dm1_female==. & dm2_female==.)
replace dm_gender = 3 if dm_gender==. & !(dm1_female==. & dm2_female==.)
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keep(1 3)
replace dm_gender=1 if fhh ==0 & dm_gender==. //0 changes
replace dm_gender=2 if fhh ==1 & dm_gender==. //0 changes
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep field_size plot_id hhid dm_* fhh 
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_decision_makers", replace


********************************************************************************
*ALL PLOTS
********************************************************************************
	***************************
	*Plot variables
	***************************
use "${Nigeria_GHS_W4_raw_data}/sect11f_plantingW4.dta", clear
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3i_harvestw4.dta", nogen
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3iii_harvestw4.dta", nogen
	ren plotid plot_id
	merge m:1 hhid plot_id using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_areas.dta", nogen keep(3) //100 unmatched obs dropped - unsurveyed households?
	gen percent_field = s11fq1
	replace percent_field=s11fq4 if percent_field==.
	gen ha_planted = percent_field/100*field_size //"Naive" hectares planted; total area of crop on plot might be greater than the field size due to counting interplanted or subdivided crops as covering the full plot.
	gen ha_harvest = ha_planted if sa3iq4b ==2 | sa3iiiq7==1 //Was area planted less than area harvested? 2=No / In the last 12 months, has your household harvested any <Tree Crop>? They don't ask for area harvested, so I assume that the whole area is harvested (not true for some crops)
	replace ha_harvest=ha_planted*sa3iq5/100 if ha_harvest==.
	replace sa3iq3 = 1 if sa3iq6i!=0 & sa3iq6i!=.
	replace ha_harvest = 0 if sa3iq3==2
	//ALT: About 900 obs at this point do not have area harvested; mainly tree crops where # of trees is known but planted area is not.
	
	/*ALT: At this point we have several options for how we want to resolve contradictions between planted and harvested area; we can either assume that the harvested hectares are accurate and always less than or equal to area planted and replace area 
	planted where there are contradictions. We can also try rescaling area planted by adjusting plots where more than 100% of the area is reported planted to ensure plantings fit into the reported plot area; this process is made somewhat complex
	because of tree crops.  Or we can leave them alone for now (what I do for the raw data).
	*/
	*gen plant_date = ym(s11fq3_2, s11fq3_1)
	*format plant_date %tm
	*gen harv_date = ym(sa3iq4a2, sa3iq4a1)
	*format harv_date %tm
	*gen harv_end = ym(sa3iq6c2, sa3iq6c1)
	*format harv_end %tm
	
	gen planting_year = s11fq3_2
	gen planting_month = s11fq3_1
	gen harvest_month_begin = sa3iq4a1
	gen harvest_year_begin = sa3iq4a2
	gen harvest_year_end = sa3iq6c2
	gen harvest_month_end = sa3iq6c1
	

		merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_coords.dta", nogen keep(1 3)
		merge m:1 hhid plot_id using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm_gender)
		decode zone, g(adm1)
		replace adm1 = substr(adm1, 4,.)
		decode state, g(adm2)
		replace adm2 = substr(adm2, (strpos(adm2, ".")+2), .)
		decode lga, g(adm3)
		replace adm3 = substr(adm3, (strpos(adm3, ".")+2), .)
		tostring ea, replace force 
		replace ea = "moved" if ea=="0"
		ren ea adm4

		decode cropcode, g(crop)
		replace crop = substr(crop, (strpos(crop, ".")+2), .)
		ren percent_field crop_area_share
		gen season = "main season"
		keep adm* hhid plot_id crop crop_area_share planting_month planting_year harvest_month_begin harvest_month_end harvest_year_begin harvest_year_end gps_meas dm_gender plot_area_measured_ha plot_area_reported_ha plot_area_reported_localUnit localUnit_area season
		merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hh_coords.dta", nogen keep(1 3)
		ren hhid hhID
		ren plot_id plotID
		gen dataset_name = "NGA_2018_GHSP-W4_v03_M"
		gen dataset_doi = "https://doi.org/10.48529/1hgw-dq47"
		gen wave = 2018
		gen country="Nigeria"
		save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_all_plots_date_raw.dta", replace
		export delimited using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_results.csv", replace



