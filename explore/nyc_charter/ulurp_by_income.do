
global data "${dropbox}/development/data/raw"
global export "${dropbox}/development/figures/nyc_charter"


*-------------------------------------------------------------------------------
*Load in Tract Level Income
*-------------------------------------------------------------------------------
import delim "${data}/nhgis/income1970/income_1970", clear
bys statea tracta countya: keep if _n == 1  

*Keep if NYC 
keep if statea == 36 & inlist(countya, 5,47,61,81,85)


*Converting



egen total_pop = rowtotal(c3t*)

keep statea countya tracta c3t* total_pop

reshape long c3t, i(statea countya tracta total_pop ) j(var) string
destring var, replace 	

egen tract = group(statea countya tracta)

xtset tract var 

gen cum = c3t if var == 1 
replace cum = l1.cum + c3t if var != 1 

gen median_pop = total_pop/2
gen above_median = cum > median_pop
keep if above_median == 1 
bys statea countya tracta (var): keep if _n == 1 

gen median_income = . 
replace median_income = 500 if var == 1 
replace median_income = 1500 if var == 2
replace median_income = 2500 if var == 3
replace median_income = 3500 if var == 4
replace median_income =4500 if var == 5
replace median_income =5500 if var == 6
replace median_income =6500 if var == 7
replace median_income =7500 if var == 8
replace median_income =8500 if var == 9
replace median_income =9500 if var == 10
replace median_income =11000 if var == 11
replace median_income =13500 if var == 12
replace median_income =20000 if var == 13
replace median_income =37500 if var == 14
replace median_income =50000 if var == 15



* Convert state, county, and tract to string with leading zeros
replace tracta = tracta*100 if tracta<1000

gen str2 state_str = string(statea, "%02.0f")
gen str3 county_str = string(countya, "%03.0f")
gen str6 tract_str = string(tracta, "%06.0f")

* Concatenate the strings to form the GEOID
gen geoid = state_str + county_str + tract_str

drop state* county* tract*

bys geoid: drop if _n != 1 

isid geoid 

sum median_income, d 


tempfile censusincome 
save `censusincome'



*-------------------------------------------------------------------------------
*Convert Tracts to 2010
*-------------------------------------------------------------------------------
use "${data}/xw/crosswalk_1970_2010", clear

rename trtid70 geoid

merge m:1 geoid using `censusincome', keep(2 3)

collapse (mean) median_income [w=weight], by(trtid10)
rename trtid10 geoid

tempfile income_tract 
save `income_tract'

*-------------------------------------------------------------------------------
*Assign BBL to Tracts
*-------------------------------------------------------------------------------

use "${data}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear

gen county = . 

replace county = 5 if Borough == "BX"
replace county = 47 if Borough == "BK"
replace county = 61 if Borough == "MN"
replace county = 81 if Borough == "QN"
replace county = 85 if Borough == "SI"

gen len = strlen(Tract2010)
replace Tract2010 = Tract2010+"00" if len == 4
rename Tract2010 tract_str

keep BoroCode Block Lot BBL tract_str county
rename (BoroCode Block Lot BBL ) (boro block lot bbl )


gen str3 county_str = string(county, "%03.0f")

* Concatenate the strings to form the GEOID
gen geoid = "36" + county_str + tract_str

*Some BBLs Dropped
merge m:1 geoid using `income_tract', keep(3) nogen

keep boro block lot bbl median_income
tempfile bbl_xw
save `bbl_xw'




import delim "${data}/nyc_housing/nyc_zap/zapprojectbbls_20240101csv/zap_projectbbls", clear bindquote(strict)

merge m:1 bbl using `bbl_xw', keep(1 3)


collapse (mean) median_income, by(project_id)

tempfile bbl_income 
save `bbl_income'

*-------------------------------------------------------------------------------
*Merge with ULURP
*-------------------------------------------------------------------------------
import delim "${data}/nyc_housing/nyc_zap/zapprojects_20240101csv/zap_projects", clear bindquote(strict)

merge 1:1 project_id using `bbl_income'

keep if _merge == 3 


replace project_brief = strlower(project_brief)


gen match = _merge == 3 

gen date = date(certified_referred, "YMD")
gen year = year(date)
gen count = project_status == "Complete"

keep if ulurp_non == "ULURP"

gen failed = inlist(project_status, "Terminated", "Withdrawn-Other")

gen q = . 
replace q = 1 if median_income <= 7500 
replace q = 2 if median_income <= 11000 & mi(q)
replace q = 3 if median_income > 11000 & !mi(median_income)

gen dispo = 0 
replace dispo = 1 if strpos(project_brief, "dispo") != 0

*keep if dispo == 0 

collapse (rawsum) count (mean) failed, by(year q)

tw (connect count year if q == 1 & year >= 1980) ///
(connect count year if q == 2 & year >= 1980 ) ///
(connect count year if q == 3  & year >= 1980), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
legend(order(1 "Median Income Below 7500" ///
 2 "Median Income Between 7500-11000"  ///
 3 "Median Income Above 11000" ) ring(0) pos(2) col(1) size(medium)) ///
 ytitle("Land Use Changes")
 e
 graph export "${export}/ulurp_by_income.pdf", replace
 
 
 tw (connect failed year if q == 1 ) ///
(connect failed year if q == 2 ) ///
(connect failed year if q == 3 ), ///
xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
legend(order(1 "Median Income Below 7500" ///
 2 "Median Income Between 7500-11000"  ///
 3 "Median Income Above 11000" ) ring(0) pos(2) col(1) size(medium)) ///
 ytitle("Failure Rate")
 
 graph export "${export}/ulurp_fail_by_income.pdf", replace

 *drop if mi(q)
 collapse (rawsum) count, by(year)
 
 tw connect count year
