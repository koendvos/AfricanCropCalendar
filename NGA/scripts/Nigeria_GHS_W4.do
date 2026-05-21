
clear
clear matrix
clear mata
program drop _all
set more off
set maxvar 10000


//set directories
*Nigeria General HH survey (NG LSMS)  Wave 4

global Nigeria_GHS_W4_raw_data			"../data"
global Nigeria_GHS_W4_created_data 		"../out"

global Nigeria_GHS_W4_pop_tot 195874740
global Nigeria_GHS_W4_pop_rur 97263561
global Nigeria_GHS_W4_pop_urb 98611179



********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/secta_plantingw4.dta", clear
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave4 rural
ren wt_wave4 weight
drop if weight == . 
*DYA.11.21.2020 from the the BID
*"The final sample consisted of 4,976 households of which 1,425 were from the long panel sample and 3,551 from the refresh sample."
*Now sure why we have 5,263 obs in this file.
*It seems that Overall, 34 refresh EAs were inaccessible during the listing period or post-planting visit. 
*The EAs were highly concentrated in the North East and North Central Zones where conflict (insurgency and farmer-herder attacks) were prevalent during this period.
*But these likely show up this this file explaing why with have 287 a additional households.
duplicates report hhid
//merge 1:1 hhid using  "${Nigeria_GHS_W4_created_data}\Nigeria_GHS_W4_weights.dta", keep(2 3) nogen  // keeping hh surveyed
save  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", replace


********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}/sect1_plantingw4.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W4_raw_data}/sect1_harvestw4.dta"
replace season="harv" if season==""
*keep if s1q4==1 //Drop individuals who've left household   // AYW_3.5.20 This question wasn't asked of all individuals. 
gen member = s1q4
replace member = 1 if s1q3 != . 
drop if member!=1
gen female= s1q2==2
gen fhh = s1q3==1 & female
recode fhh (.=0)
preserve 
collapse (max) fhh, by(hhid)
tempfile fhh
save `fhh'
restore 
la var female "1= individual is female"
ren s1q6 age
la var age "Individual age"
keep hhid indiv female age season
ren female female_
ren age age_ 
reshape wide female_ age_, i(hhid indiv) j(season) string
gen age = age_plan 
replace age=age_harv if age==.
gen female=female_plan 
replace female=female_harv if female==.
drop *harv *plan
merge m:1 hhid using `fhh'
merge m:1 hhid using  "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", keep(2 3) nogen  // keeping hh surveyed
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_person_ids.dta", replace


//ALT: This rescales the weights to match the population better (original weights underestimate total population and overestimate rural population)
********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_person_ids.dta", clear
gen member=1
collapse (max) fhh (sum) hh_members=member, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
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
keep hhid zone state lga ea weight* rural
save "${Nigeria_GHS_W4_created_data}\Nigeria_GHS_W4_weights.dta", replace

********************************************************************************
*GPS COORDINATES *
********************************************************************************
use "${Nigeria_GHS_W4_raw_data}\nga_householdgeovars_y4.dta", clear
merge 1:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhids.dta", nogen keep(3) 
ren lat_dd_mod lat
ren lon_dd_mod lon
//ALT: Per the BID, coordinates are supposed to represent the ea centroid, so I'm not sure why there are multiple (sometimes substantially different) sets of coordinates for some eas.
keep hhid lat lon
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

ren s11aq6a indiv1
ren s11aq6b indiv2
ren s11aq6c indiv3
ren s11aq6d indiv4

replace indiv1 = sa1q2 if indiv1==. //Post-Harvest (only reported for "new" plot)
replace indiv2 = sa1q2c_1 if indiv2==.
replace indiv3 = sa1q2c_2 if indiv3==. //The ph questionnaire goes up to six for ph but we'll stick to the first four for consistency with the pp questionnaire 
replace indiv4 = sa1q2c_3 if indiv4==.
replace indiv1 = s11b1q6_1 if indiv1==. & indiv2==. & indiv3==. & indiv4==. //plot owner if dm is empty

la var indiv1 "Primary plot manager (indiv id)"
la var indiv2 "First Secondary plot manager (indiv id)"
la var indiv3 "Second secondary plot manager (indiv id)"
la var indiv4 "Third secondary plot manager (indiv id)"
 
drop s11* sa1*
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_areas.dta", replace

//ALT: Gender of plot decisionmaker - worth including to see if there are gender-based differences in planting timing?
********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************
use "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_areas.dta", clear 	
keep hhid plot_id indiv* cultivate //ALT: Based on crop reporting numbers I would take the cultivate response with a grain of salt. 
reshape long indiv, i(hhid plot_id cultivate) j(indivno)
collapse (min) indivno, by(hhid plot_id indiv cultivate) //Removing excess observations to accurately estimate the number of decisionmakers in mixed-managed plots. Taking the highest rank
//At this point, we have the decisionmakers and their relative priority level, as the questionnaire asks to go in descending order of importance. This may be relevant for some applications (e.g., you want only the primary decisionmaker; keep if indivno==1), but we don't use it here.
drop if indiv==.
merge m:1 hhid indiv using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_person_ids.dta", nogen keep(1 3) keepusing(female) 
preserve 
keep hhid plot_id indiv female
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_dm_ids.dta", replace
restore
gen dm1_gender = female+1 if indivno==1
collapse (mean) female (firstnm) dm1_gender, by(hhid plot_id)
*Constructing three-part gendered decision-maker variable; male only (=1) female only (=2) or mixed (=3)
gen dm_gender = 3 if female !=1 & female!=0 & female!=.
replace dm_gender = 1 if female == 0
replace dm_gender = 2 if female == 1
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_hhsize.dta", nogen keep(1 3)
replace dm1_gender=fhh+1 if dm_gender==.
replace dm_gender=fhh+1 if dm_gender==.
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep plot_id hhid dm* //fhh 
save "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_decision_makers", replace


********************************************************************************
*ALL PLOTS
********************************************************************************
	***************************
	*Plot variables
	***************************
use "${Nigeria_GHS_W4_raw_data}/sect11f_plantingW4.dta", clear
	gen crop_code_11f = cropcode
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3i_harvestw4.dta", nogen
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W4_raw_data}/secta3iii_harvestw4.dta", nogen
	//ren cropcode crop_code_a3i 
	ren plotid plot_id
	ren s11fq5 number_trees_planted
	gen use_imprv_seed=s11fq3b==1
	
	gen perm_crop = s11fq0==2
	replace perm_crop = 1 if cropcode==1020 //I don't see any indication that cassava is grown as a seasonal crop in Nigeria
	//replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	//replace crop_code_a3i = crop_code_11f if crop_code_a3i==.
	//gen cropcode =crop_code_11f //Generic level
	replace cropcode = crop_code_11f if cropcode==.
	drop if cropcode == 1010 & ((hhid==50053 & plot_id==2) | (hhid==209107 & plot_id==1)) //Reported as mistaken entries in sa3iq4_os
	recode cropcode (2170=2030) (2142 = 2141) /*(1121 1122 1123 1124=1120)*/ //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave. //Okay to lump yams for price and unit conversions, not for other things. 
	replace cropcode = 4010 if strpos(sa3iq4_os, "FEED") | regexm(sa3iq4_os, "CONSUMP*TION") | regexm(sa3iq4_os, "ONLY.+LEAVES")
	drop if strpos(sa3iq4_os, "FALLOW") | regexm(sa3iq4_os, "NO.+PLANT") | strpos(sa3iq4_os, "MISTAK")
	label define CROPCODE 1120 "1120. YAM" 4010 "4010. FODDER", add
	la values cropcode CROPCODE
	merge m:1 hhid plot_id using "${Nigeria_GHS_W4_created_data}/Nigeria_GHS_W4_plot_areas.dta", nogen keep(3) //ALT 05.03.23
	gen percent_field = s11fq1/100
	replace percent_field = s11fq4/100 if percent_field==. 
	recode percent_field field_size (0=.)
	
	bys hhid plot_id : egen tot_pct_planted = sum(percent_field)
	gen miss_pct = percent_field==. 
	bys hhid plot_id : egen tot_miss = sum(miss_pct)
	gen underplant_pct = 1-tot_pct_planted 
	replace percent_field = underplant_pct/tot_miss if miss_pct & underplant_pct > 0 
	replace percent_field = percent_field/tot_pct_planted if tot_pct_planted > 1
	gen ha_planted = percent_field*field_size
	
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
		export delimited using "../out/NGA_2018-19.csv", replace



