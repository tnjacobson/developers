
global data "${dropbox}/development/data/raw"
global export "${dropbox}/development/figures/nyc_charter"


*-------------------------------------------------------------------------------
*Define Income Bins Using 2010 Census
*-------------------------------------------------------------------------------
import delim "${data}/nhgis/acs_2010_2014_income/nhgis0023_ds206_20145_tract.csv", clear
keep statea countya tracta abdpe001
rename abdpe001 income
rename (statea countya tracta) (state county tract)
keep if state == 36 & inlist(county, 5,47,61,81, 85)

sum income, d 
local q1 = `r(p25)'
local q4 = `r(p75)'


tempfile census
save `census'


*-------------------------------------------------------------------------------
*Map BBL to Tract and Load Income
*-------------------------------------------------------------------------------

*BBL to Tract
use "${data}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear

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

merge m:1 tract county using `census', keep(1 3) gen(merge_income)

tempfile bbl 
save `bbl'


*-------------------------------------------------------------------------------
*Use Block Averages if Missing
*-------------------------------------------------------------------------------


*Computing Average Income in Block
gen double bb = floor(bbl/10000)*10000
collapse (mean) income, by(bb)
 drop if mi(bb)
 rename income income_bb
tempfile bb 
save `bb' 
 

*-------------------------------------------------------------------------------
*Merge on Incomes to BBLs
*-------------------------------------------------------------------------------

import delim "${data}/nyc_housing/nyc_zap/zapprojectbbls_20240101csv/zap_projectbbls", clear bindquote(strict)

keep project_id bbl

merge m:1 bbl using `bbl', keep(1 3) gen(merge_pluto)

gen no_lot = mod(bbl, 10000) == 0

gen double bb = floor(bbl/10000)*10000

merge m:1 bb using `bb', nogen keep(1 3)


replace income = income_bb if mi(income)

collapse (mean) income, by(project_id)

tempfile projects
save `projects'



*-------------------------------------------------------------------------------
*Load in Project Information
*-------------------------------------------------------------------------------


import delim "${data}/nyc_housing/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)

merge 1:m project_id using `projects', keep(1 3) 

gen date = date(certified_referred, "YMD")
gen year = year(date)


gen has_bbl = _merge == 3 
gen has_income = !mi(income)


keep if project_status == "Complete"
keep if ulurp_non == "ULURP"
gen count = 1

replace project_brief = strlower(project_brief)
gen c_zoning = strpos(project_brief, "zoning") != 0 | strpos(project_brief, "rezone") != 0 | strpos(project_brief, "zm") != 0 | strpos(project_brief, "za") != 0 
gen c_dispo = strpos(project_brief, "dispo") != 0 | strpos(project_brief, "sale of") != 0
gen c_acq = strpos(project_brief, "acq") != 0 
gen c_map =  strpos(project_brief, "map") != 0 
gen c_spec_perm = strpos(project_brief, "special permit") != 0 | strpos(project_brief, "spec perm") != 0 
gen c_sidewalk =  strpos(project_brief, "sidewalk") != 0

gen c_zoning_map = c_zoning == 1 | c_map == 1 
gen c_disp_acq = c_dispo == 1 | c_acq == 1 
gen c_un = c_zoning_map == 0 & c_disp_acq == 0

gen c_zm = strpos(ulurp_numbers, "Z") != 0 
gen c_disp2 = strpos(ulurp_numbers, "PP") != 0 | ///
	strpos(ulurp_numbers, "PQ") != 0 
gen c_landfill = strpos(ulurp_numbers, "ML") != 0 
gen c_urban = strpos(ulurp_numbers, "HU") != 0 

binscatter c_disp2 year, line(connect)
e

*-------------------------------------------------------------------------------
*Assess Missing Geographies
*-------------------------------------------------------------------------------

preserve 
foreach var of varlist c_* count {
	gen `var'_bbl = `var' if has_bbl == 1 
	gen `var'_inc = `var' if has_income == 1 
}


collapse (rawsum) count count_bbl count_inc c_*, by(year)

tw (connect count year) ///
(connect count_bbl year), ///
ytitle("Total Land Use Changes") ///
xtitle("Year") ///
legend(order(1 "Total" 2 "With Geography") ring(0) pos(2) col(1) size(medium))
graph export "${export}/ulurp_geo.pdf", replace 

tw (connect c_zm year) ///
(connect c_zm_bbl  year), ///
ytitle("Total Zoning Changes") ///
xtitle("Year") ///
legend(order(1 "Total" 2 "With Geography") ring(0) pos(2) col(1) size(medium))
graph export "${export}/zoning_changes_geo.pdf" , replace

tw (connect c_disp2 year) ///
(connect  c_disp2_bbl  year), ///
ytitle("Total Land Transactions") ///
xtitle("Year") ///
legend(order(1 "Total" 2 "With Geography") ring(0) pos(2) col(1) size(medium))
graph export "${export}/disp_acq_geo.pdf" , replace 

restore


*-------------------------------------------------------------------------------
*Explore Time Series By Income
*-------------------------------------------------------------------------------


drop if mi(income)

gen q = 2 
replace q = 1 if income <= `q1'
replace q = 3 if income >= `q4'


collapse (rawsum) c_* count  , by(year q )

keep if year >= 1980

tw 	(connect count year if q == 1 ) ///
	(connect count year if q == 2 ) ///
	(connect count year if q == 3 ), ///
	xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
	ytitle("Total Land Use Changes") ///
	xtitle("Year") ///
	legend(order(1 "Q1" 2 "Q2-3" 3 "Q4") ring(0) pos(2) col(1) size(medium))
graph export "${export}/total_changes_income.pdf" , replace 


tw 	(connect c_zm year if q == 1 ) ///
	(connect c_zm year if q == 2 ) ///
	(connect c_zm year if q == 3 ), ///
	xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
	ytitle("Zoning Changes") ///
	xtitle("Year") ///
	legend(order(1 "Q1" 2 "Q2-3" 3 "Q4") ring(0) pos(2) col(1) size(medium))
graph export "${export}/zoning_changes_income.pdf" , replace 

tw 	(connect c_disp2 year if q == 1 ) ///
	(connect c_disp2 year if q == 2 ) ///
	(connect c_disp2 year if q == 3 ), ///
	xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
	ytitle("Land Transactions") ///
	xtitle("Year") ///
	legend(order(1 "Q1" 2 "Q2-3" 3 "Q4") ring(0) pos(2) col(1) size(medium))
graph export "${export}/transactions_income.pdf" , replace 
	
*-------------------------------------------------------------------------------
*Explore Time Series
*-------------------------------------------------------------------------------

collapse (rawsum) count c_*, by(year)

tw 	(connect c_zm year) ///
	(connect c_disp2 year), ///
	xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
	ytitle("Approved Changes") ///
	xtitle("Year") ///
	legend(order(1 "Zoning Changes" 2 "Land Transactions") ring(0) pos(2) col(1) size(medium))
graph export "${export}/ts_changes_new.pdf" , replace  


	
	
	
