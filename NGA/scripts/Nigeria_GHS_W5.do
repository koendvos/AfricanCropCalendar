
clear
clear matrix
clear mata
program drop _all
set more off
set maxvar 10000


*Set location of raw data and output
//global directory			".."

//set directories
*Nigeria General HH survey (NG LSMS)  Wave 4

global Nigeria_GHS_W5_raw_data			"../data"
global Nigeria_GHS_W5_created_data 		"../out"

global Nigeria_GHS_W5_pop_tot 227882945
global Nigeria_GHS_W5_pop_rur 104181246
global Nigeria_GHS_W5_pop_urb 123701699

********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/secta_plantingw5.dta", clear
keep if interview_result==1
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea wt_wave5 wt_longpanel_wave5 wt_cross_wave5 rural
ren wt_wave5 weight // 
ren wt_longpanel_wave5 weight_longpanel
ren wt_cross_wave5 weight_crosssection
drop if weight==. & weight_longpanel==. & weight_crosssection==.
duplicates report hhid
save  "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhids.dta", replace

********************************************************************************
* INDIVIDUAL IDS *
********************************************************************************
use "${Nigeria_GHS_W5_raw_data}/sect1_plantingw5.dta", clear
gen season="plan"
append using "${Nigeria_GHS_W5_raw_data}/sect1_harvestw5.dta"
replace season="harv" if season==""
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
merge m:1 hhid using  "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhids.dta", keep(2 3) nogen  // keeping hh surveyed
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", replace


********************************************************************************
* HOUSEHOLD SIZE *
********************************************************************************
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", clear
gen member=1
collapse (max) fhh (sum) hh_members=member, by (hhid)
lab var hh_members "Number of household members"
lab var fhh "1= Female-headed household"
*DYA.11.1.2020 Re-scaling survey weights to match population estimates
merge 1:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhids.dta", nogen keep(2 3)
*Adjust to match total population
total hh_members [pweight=weight]
matrix temp =e(b)
gen weight_pop_tot=weight*${Nigeria_GHS_W5_pop_tot}/el(temp,1,1)
total hh_members [pweight=weight_pop_tot]
lab var weight_pop_tot "Survey weight - adjusted to match total population"
*Adjust to match total population but also rural and urban
total hh_members [pweight=weight] if rural==1
matrix temp =e(b)
gen weight_pop_rur=weight*${Nigeria_GHS_W5_pop_rur}/el(temp,1,1) if rural==1
total hh_members [pweight=weight_pop_tot]  if rural==1

total hh_members [pweight=weight] if rural==0
matrix temp =e(b)
gen weight_pop_urb=weight*${Nigeria_GHS_W5_pop_urb}/el(temp,1,1) if rural==0
total hh_members [pweight=weight_pop_urb]  if rural==0

egen weight_pop_rururb=rowtotal(weight_pop_rur weight_pop_urb)
total hh_members [pweight=weight_pop_rururb]  
lab var weight_pop_rururb "Survey weight - adjusted to match rural and urban population"
drop weight_pop_rur weight_pop_urb
keep hhid zone state lga ea weight* rural hh_members fhh
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_weights.dta", replace

********************************************************************************
*GPS COORDINATES *
********************************************************************************
//No GPS coordinates included in Nigeria W5 


********************************************************************************
* PLOT AREAS *
********************************************************************************
*starting with planting
//ALT IMPORTANT NOTE: As of W4, the implied area conversions for farmer estimated units (including hectares) are markedly different from previous waves. I recommend excluding plots that do not have GPS measured areas from any area-based productivity estimates.
use "${Nigeria_GHS_W5_raw_data}/sect11a1_plantingw5.dta", clear
*merging in planting section to get cultivated status
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/sect11b1_plantingw5.dta", nogen
*merging in harvest section to get areas for new plots
merge 1:1 hhid plotid using "${Nigeria_GHS_W5_raw_data}/secta1_harvestw5.dta", gen(plot_merge)
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_hhids.dta", nogen keep( 3)
ren s11aq3_number area_size
ren s11aq3_unit area_unit
ren sa1q1c area_size2 //GPS measurement, no units in file
//ren sa1q9b area_unit2 //Not in file
ren s11mq3 area_meas_sqm
//ren sa1q9c area_meas_sqm2
gen cultivate = sa1q1a ==1 
*assuming new plots are cultivated
//replace cultivate = 1 if sa1q1aa==1
//replace cultivate = 1 if sa1q3==1 //ALT: This has changed to respondent ID for w5
*using conversion factors from LSMS-ISA Nigeria Wave 2 Basic Information Document (Wave 3 unavailable, but Waves 1 & 2 are identical) 
*found at http://econ.worldbank.org/WBSITE/EXTERNAL/EXTDEC/EXTRESEARCH/EXTLSMS/0,,contentMDK:23635560~pagePK:64168445~piPK:64168309~theSitePK:3358997,00.html
*General Conversion Factors to Hectares
//		Zone   Unit         Conversion Factor
//		All    Plots        0.0667
//		All    Acres        0.4
//		All    Hectares     1
//		All    Sq Meters    0.0001
// 	    All	   100x100 sq ft 0.09290304
//      All    100x50 sq ft  0.04645152
//      All    Football field 0.721159848  //According to FIFA, a standard football field is 110-120 yards long and 70-80 yards wide (roughly 8625 sq yd)

*Zone Specific Conversion Factors to Hectares
//		Zone           Conversion Factor
//				 Heaps      Ridges      Stands
//		1 		 0.00012 	0.0027 		0.00006
//		2 		 0.00016 	0.004 		0.00016
//		3 		 0.00011 	0.00494 	0.00004
//		4 		 0.00019 	0.0023 		0.00004
//		5 		 0.00021 	0.0023 		0.00013
//		6  		 0.00012 	0.00001 	0.00041


*farmer reported field size for post-planting
gen field_size= area_size if area_unit==6
replace field_size = area_size*0.0667 if area_unit==4									//reported in plots
replace field_size = area_size*0.404686 if area_unit==5		    						//reported in acres
replace field_size = area_size*0.0001 if area_unit==7									//reported in square meters
replace field_size = area_size*0.09290304 if area_unit==8
replace field_size = area_size*0.04645152 if area_unit==9
replace field_size = area_size*0.721159848 if area_unit==10

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

/*ALT 02.23.23*/ gen area_est = field_size
*replacing farmer reported with GPS if available
gen area_meas_hectares =  area_meas_sqm*0.0001 if area_meas_sqm!=.  & area_meas_sqm!=0
replace field_size=area_meas_hectares if area_meas_hectares!=.	
gen gps_meas = (area_meas_sqm!=. & area_meas_sqm !=0)
decode area_unit, g(localUnit_area)
replace localUnit_area = substr(localUnit_area, (strpos(localUnit_area, ".")+2), .)
ren area_size plot_area_reported_localUnit 
ren area_est plot_area_reported_ha 
ren area_meas_hectares plot_area_measured_ha 

la var gps_meas "Plot was measured with GPS, 1=Yes"
ren plotid plot_id


ren s11aq5a indiv1
ren s11aq5b indiv2
ren s11aq5c indiv3
ren s11aq5d indiv4

replace indiv1 = sa1q11_1 if indiv1==. //Post-Harvest (only reported for "new" plot)
replace indiv2 = sa1q11_2 if indiv2==.
replace indiv3 = sa1q11_3 if indiv3==. //The ph questionnaire goes up to six for ph but we'll stick to the first four for consistency with the pp questionnaire 
replace indiv4 = sa1q11_4 if indiv4==.
replace indiv1 = s11b1q7_1 if indiv1==. & indiv2==. & indiv3==. & indiv4==. //plot owner if dm is empty

la var indiv1 "Primary plot manager (indiv id)"
la var indiv2 "First Secondary plot manager (indiv id)"
la var indiv3 "Second secondary plot manager (indiv id)"
la var indiv4 "Third secondary plot manager (indiv id)"

drop s11* sa1*
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_areas.dta", replace

********************************************************************************
* PLOT DECISION MAKERS *
********************************************************************************
use "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_areas.dta", clear
keep hhid plot_id indiv* cultivate //ALT: Based on crop reporting numbers I would take the cultivate response with a grain of salt. 
reshape long indiv, i(hhid plot_id cultivate) j(indivno)
collapse (min) indivno, by(hhid plot_id indiv cultivate) //Removing excess observations to accurately estimate the number of decisionmakers in mixed-managed plots. Taking the highest rank
//At this point, we have the decisionmakers and their relative priority level, as the questionnaire asks to go in descending order of importance. This may be relevant for some applications (e.g., you want only the primary decisionmaker; keep if indivno==1), but we don't use it here.
drop if indiv==.
merge m:1 hhid indiv using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_person_ids.dta", nogen keep(1 3) keepusing(female)
preserve 
keep hhid plot_id indiv female
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_dm_ids.dta", replace
restore
gen dm1_gender = female+1 if indivno==1
gen dm1_id = indiv if indivno==1
collapse (mean) female (firstnm) dm1_gender dm1_id, by(hhid plot_id)
*Constructing three-part gendered decision-maker variable; male only (=1) female only (=2) or mixed (=3)
gen dm_gender = 3 if female !=1 & female!=0 & female!=.
replace dm_gender = 1 if female == 0
replace dm_gender = 2 if female == 1
la def dm_gender 1 "Male only" 2 "Female only" 3 "Mixed gender"
*replacing observations without gender of plot manager with gender of HOH
merge m:1 hhid using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_weights.dta", nogen keep(1 3)
replace dm1_gender=fhh+1 if dm_gender==.
gen dm_male = dm_gender==1
gen dm_female = dm_gender==2
gen dm_mixed = dm_gender==3
keep plot_id hhid dm* //fhh 
save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_decision_makers", replace

********************************************************************************
*ALL PLOTS
********************************************************************************
	***************************
	*Plot variables
	***************************
use "${Nigeria_GHS_W5_raw_data}/sect11f_plantingw5.dta", clear
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W5_raw_data}/secta3i_harvestw5.dta", nogen
	merge 1:1 hhid plotid cropcode using "${Nigeria_GHS_W5_raw_data}/secta3iii_harvestw5.dta", nogen
	gen use_imprv_seed=s11fq7==1
	replace use_imprv_seed = s11fq18==1 if s11fq7==.
	gen crop_code_long = cropcode
	//ren cropcode crop_code_a3i 
	ren plotid plot_id
	ren s11fq15 number_trees_planted
	//replace crop_code_11f=crop_code_a3i if crop_code_11f==.
	//replace crop_code_a3i = crop_code_11f if crop_code_a3i==.
	//gen cropcode =crop_code_11f //Generic level
	//replace cropcode = crop_code_11f if cropcode==.
	drop if strpos(sa3iq4_os, "WRONGLY") | strpos(sa3iq4_os, "MISTAKEN") | strpos(sa3iq4_os, "DIDN'T") | strpos(sa3iq4_os, "did not") | strpos(sa3iq4_os, "DID NOT") //Reported as mistaken entries in sa3iq4_os
	recode cropcode (2170=2030) (2142 = 2141) /*(1121 1122 1123 1124=1120)*/ //Only things that carry over from W3 are bananas/plantains, yams, and peppers. The generic pepper category 2040 in W3 is missing from this wave. //Okay to lump yams for price and unit conversions, not for other things. 
	//replace cropcode = 4010 if strpos(sa3iq4_os, "FEED") | regexm(sa3iq4_os, "CONSUMP*TION") | regexm(sa3iq4_os, "ONLY.+LEAVES") //no one reported fodder in this question for w5.
	label def Sec11f_crops__id 1120 "1120. YAM" 4010 "4010. FODDER", modify
	la values cropcode Sec11f_crops__id
	merge m:1 hhid plot_id using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_areas.dta", nogen keep(3) //ALT 05.03.23
	gen percent_field = s11fq3/100
	replace percent_field = s11fq14/100 if percent_field==. 
	recode percent_field field_size (0=.)

	//for tree crops not part of an orchard, the area planted is not recorded; this divides the missing area by the number of tree crops on the plot 
	bys hhid plot_id : egen tot_pct_planted = sum(percent_field)
	gen miss_pct = percent_field==. 
	bys hhid plot_id : egen tot_miss = sum(miss_pct)
	gen underplant_pct = 1-tot_pct_planted 
	replace percent_field = underplant_pct/tot_miss if miss_pct & underplant_pct > 0 //175/241 fixed, remainder are overplanted. 
	replace percent_field=percent_field/tot_pct_planted if tot_pct_planted > 1
	gen ha_planted = percent_field*field_size
	
	gen pct_harvest=1 if sa3iq6 ==2 | sa3iiiq17==1 //Was area planted less than area harvested? 2=No / In the last 12 months, has your household harvested any <Tree Crop>? They don't ask for area harvested, so I assume that the whole area is harvested (not true for some crops)
	replace pct_harvest = sa3iq8/100 if sa3iq8!=. //1075 obs
	replace pct_harvest = 0 if pct_harvest==. & sa3iq4_1 <= 18  
	replace pct_harvest = . if pct_harvest==0 & sa3iq4_1 > 18 & sa3iq4_1 < 96
	gen ha_harvest=pct_harvest*ha_planted
	
	gen planting_year = s11fq11_year
	gen planting_month = s11fq11_month
	gen harvest_month_begin = sa3iq5a
	gen harvest_year_begin = sa3iq5b
	//tree crops
	replace harvest_month_begin = sa3iiiq18a if harvest_month_begin==.
	replace harvest_year_begin = sa3iiiq18b if harvest_year_begin==.
	replace harvest_month_begin = s11fq20a if harvest_month_begin==.
	replace harvest_year_begin = s11fq20b if harvest_year_begin==.
	//Fixing errors
	replace harvest_year_begin = planting_year if sa3iq3==1 & harvest_year_begin==.
	replace harvest_year_begin = harvest_year_begin+1 if harvest_year_begin==planting_year & harvest_month_begin <= planting_month
	//harvst end
	gen harvest_month_end = sa3iiiq22a
	gen harvest_year_end = sa3iiiq22b
	replace harvest_month_end = s11fq20c if harvest_month_end==.
	replace harvest_year_end = s11fq20d if harvest_year_end==. //Two entries for tree crops, some of these are outside of the survey window
	replace harvest_month_end = sa3iq14a if harvest_month_end==.
	replace harvest_year_end = sa3iq14b if harvest_year_end==.
	replace harvest_month_end =harvest_month_begin if harvest_month_end==. & sa3iq11==1
	replace harvest_year_end = harvest_year_begin if harvest_year_end < harvest_year_begin
	replace harvest_year_end = harvest_year_end+1 if harvest_year_end == planting_year & harvest_month_end <= planting_month

		
		merge m:1 hhid plot_id using "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_plot_decision_makers.dta", nogen keep(1 3) keepusing(dm_gender)
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
		gen lat=.
		gen lon=.
		ren hhid hhID
		ren plot_id plotID
		gen dataset_name = "NGA_2023_GHSP-W5_v01_M "
		gen dataset_doi = "https://doi.org/10.48529/zd5s-tj25"
		gen wave = 2024
		gen country="Nigeria"
		save "${Nigeria_GHS_W5_created_data}/Nigeria_GHS_W5_all_plots_date_raw.dta", replace
		export delimited using "../out/NGA_2023-24.csv", replace



