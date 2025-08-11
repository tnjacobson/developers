

global raw_data "${dropbox}/development/data/goolsbee_syverson/housing_construction"
global derived "${dropbox}/development/data/derived"
global env_data "${dropbox}/development/data/raw/env_review"


import delim "${env_data}/laws.csv", clear varnames(1)
keep state datepassed 
replace datepassed = "1970" if state == "California"
destring datepassed, replace

replace state = strlower(state)
tempfile env_review 
save `env_review'



*Load in Data on Employment

import delim "/Users/tylerjacobson/Downloads/SAINC/SAEMP25S__ALL_AREAS_1969_2001.csv", clear

replace description = strtrim(description)

gen legal = description == "Legal services"
gen total = description == "Total employment (number of jobs)"

keep if legal == 1 | total == 1 



forvalues n = 9/41 {
	rename v`n'  emp`=`n' + 1960'
}

keep geofips geoname legal emp*
reshape long emp , i(geofips geoname legal) j(year)
destring emp, replace force 

tw (connect emp year if legal == 1 & geoname == "United States")

reshape wide emp, i(geoname geofips year) j(legal)

gen frac_lawyer = emp1/emp0

tw (connect frac_lawyer year if geoname == "United States")

replace geoname = strlower(geoname)
rename geoname state 

merge m:1 state using `env_review', keep(1 3) nogen

gen has_env = !mi(datepassed)

binscatter frac_lawyer year, by(has_env) discrete line(connect)

tw (connect frac_lawyer year if state == "california")
gen treat = !mi(datepassed)
replace treat = . if state == "united states"
gen group = . 
replace group = 0 if treat == 0 
replace group = 1 if datepassed <= 1977
replace group = 2 if datepassed > 1987 & datepassed <= 1991


binscatter frac_lawyer year if state != "district of columbia", by(datepassed) line(connect) discrete

tw 	(connect emp1 year if state == "new jersey", lcolor(navy)) ///
	(connect emp1 year if state == "georgia", lcolor(maroon)), ///
	xline(1987, lpattern(dash) lcolor(navy)) ///
	xline(1991, lpattern(dash) lcolor(maroon))



