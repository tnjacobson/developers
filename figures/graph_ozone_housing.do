*Exploring NYC QOZs

global data "${dropbox}/development/data"
global output "${dropbox}/development/figures"

*-------------------------------------------------------------------------------
*Load in List of Opp Zones
*-------------------------------------------------------------------------------
use "${data}/derived/opp_zones/opp_zone_census", clear 

gen nyc = inlist(county, 5, 47,61, 81, 85) & state == 36
keep if nyc == 1 

gen proxy_elig = pov_rate > .2 & med_income < 50000
replace proxy_elig = 1 if qoz == 1 
tempfile ozones_nyc 
save `ozones_nyc'

*-------------------------------------------------------------------------------
*Load in Housing
*-------------------------------------------------------------------------------
use "${data}/derived/nyc/dob_jobs", clear 
rename gis_census_tract census_tract 
drop if mi(census_tract)
gen tract = census_tract
replace tract = tract * 100 if tract < 10000 & !inlist(mod(tract,100),1,2) 
replace tract = 200 if tract == 2 

destring borocode, replace
drop borough 
rename borocode borough 

gen county = . 
replace county = 61 if borough == 1
replace county = 5 if borough == 2
replace county = 47 if borough == 3
replace county = 81 if borough == 4
replace county = 85 if borough == 5
drop state 
gen state = 36

merge m:1 state county tract using `ozones_nyc'

gen count = 1 
gen count_apt = new_units > 3 & !mi(new_units)
gen count_large = new_units > 100 & !mi(new_units)

collapse (rawsum) count* new_units, by(qoz proxy assigned_year)

tw (connect new_units assigned_year if qoz == 1 & inrange(assigned_year,2010, 2023)) ///
(connect new_units assigned_year if qoz == 0 &proxy == 1 & inrange(assigned_year,2010, 2023)), ///
	xline(2018.9)

tw (connect count_large assigned_year if qoz == 1 & inrange(assigned_year,2010, 2023)) ///
(connect count_large assigned_year if qoz == 0 &proxy == 1 & inrange(assigned_year,2010, 2023)) ///
(connect count_large assigned_year if qoz == 0 &proxy == 0 & inrange(assigned_year,2010, 2023)), ///
	xline(2018.9)

gen size = new_units/count

tw (connect size assigned_year if qoz == 1 & inrange(assigned_year,2010, 2023)) ///
(connect size assigned_year if qoz == 0 &proxy == 1 & inrange(assigned_year,2010, 2023)) ///
(connect size assigned_year if qoz == 0 &proxy == 0 & inrange(assigned_year,2010, 2023)), ///
	xline(2018.9)
	

*-------------------------------------------------------------------------------
*Zoning Changes
*-------------------------------------------------------------------------------

*BBL to Tract
use "${data}/raw/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear

gen county = . 

replace county = 5 if Borough == "BX"
replace county = 47 if Borough == "BK"
replace county = 61 if Borough == "MN"
replace county = 81 if Borough == "QN"
replace county = 85 if Borough == "SI"

gen len = strlen(Tract2010)
replace Tract2010 = Tract2010+"00" if len == 4
destring Tract2010, replace 
rename Tract2010 tract
rename BBL bbl
keep bbl tract county
isid bbl 


merge m:1 tract county using `ozones_nyc', keep(1 3) nogen

keep bbl qoz proxy_elig 

tempfile bbl 
save `bbl'


import delim "${data}/raw/nyc_housing/nyc_zap/zapprojectbbls_20240101csv/zap_projectbbls", clear bindquote(strict)

keep project_id bbl

merge m:1 bbl using `bbl', keep(1 3) gen(merge_pluto)
gen missing = merge_pluto == 1
collapse (max) qoz proxy_elig missing, by(project_id)
tempfile project_qoz 
save `project_qoz'

import delim "${data}/raw/nyc_housing/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)

gen date = date(certified_referred, "YMD")
gen year = year(date)

merge 1:1 project_id using `project_qoz'
gen no_geo = _merge == 1 

gen count = 1
gen count_zm = strpos(ulurp_numbers, "Z") != 0 

drop if no_geo == 1 | missing == 1  

collapse (rawsum) count*, by(qoz proxy year)

tw 	(connect count_zm year if qoz == 1 & inrange(year, 2010, 2023)) ///
	(connect count_zm year if qoz == 0 & proxy == 1 & inrange(year, 2010, 2023)) ///
	(connect count_zm year if qoz == 0 & proxy == 0 & inrange(year, 2010, 2023)), ///
	xline(2018.9) xline(2017.9)
	
	
e
tw 	(connect count year if qoz == 1 & inrange(year, 2012, 2023)) ///
	(connect count year if qoz == 0 & proxy == 1 & inrange(year, 2012, 2023)), ///
	xline(2018.9) xline(2017.9)
e



e
use "${data}/derived/nyc/dob_permits_firm_ids", clear 
drop if mi(census_tract)
gen tract = census_tract
replace tract = tract * 100 if tract < 10000 & !inlist(mod(tract,100),1,2) 
replace tract = 200 if tract == 2 

gen county = . 
replace county = 61 if borough == 1
replace county = 5 if borough == 2
replace county = 47 if borough == 3
replace county = 81 if borough == 4
replace county = 85 if borough == 5

gen state = 36

merge m:1 state county tract using `ozones_nyc'
gen count = 1 
gen count_apt = 
