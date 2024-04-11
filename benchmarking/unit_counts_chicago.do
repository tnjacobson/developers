*Exploring Commercial and Housing Data


global data "${dropbox}/development/data/raw/assessor_cc"
global derived "${dropbox}/development/data/derived"

global graphics "${dropbox}/development/figures/rezoning"


*-------------------------------------------------------------------------------
*Load in Commercial Data
*-------------------------------------------------------------------------------
 import delim "${data}/commercial", clear varnames(1) bindquote(strict)
bys keypin: gen N =_N 
keep if N == 1 

*The reason there are multiple years in the data is because properties are only assessed every three years 

*Keep Properties with Residential Values
*drop if mi(tot_units)


rename brunits units_1br
rename v9 units_2br
rename v10 units_3br
rename v11 units_4br
rename studiounits units_studio
rename tot_units units_tot

egen temp = rowtotal(units_1br units_2br units_3br units_4br units_studio)
replace temp = . if temp == 0
replace units_tot = temp if mi(units_tot)

*Handle Classes
replace classes = subinstr(classes, "-","",.)
split classes, parse(",") gen(class_)
local count = r(k_new)

*Restrict to Residential Types
gen residential = 0 
forvalues i = 1/`count' {
	replace residential = 1 if inlist(substr(class_`i', 1, 1), "3","9")
}


drop if mi(units_tot)

gen count = 1 
gen count_2 = 1 if units_tot ==2 & !mi(units_tot)
gen count_34 = 1 if inlist(units_tot,3,4) & !mi(units_tot)
gen count_5 = 1 if units_tot >= 5 & !mi(units_tot)
gen count_100 = 1 if units_tot > 100 & !mi(units_tot)

collapse (rawsum) units* count*, by(yearbuilt)

rename (units* count*)=_com

rename yearbuilt year

tempfile commercial
save `commercial'

*-------------------------------------------------------------------------------
*Load in Condos
*-------------------------------------------------------------------------------
 import delim "${data}/condos_2023", clear varnames(1) bindquote(strict)

 gen units_condo = 1 
 
 collapse (rawsum) units_condo, by(year_built)
 rename year_built year 
 
 tempfile condos 
 save `condos'


*-------------------------------------------------------------------------------
*Load in Properties Data
*-------------------------------------------------------------------------------
/*import delim "${data}/parcel_universe_2023", clear varnames(1) bindquote(strict)
keep pin pin10 longitude latitude

tempfile geo 
save `geo'
*/
import delim "${data}/improvements_2023", clear varnames(1) bindquote(strict)

*Converting Pin Variable to the Right Format
*tostring pin,  format(%014.0f) replace 

*merge m:1 pin using `geo'


gen units_tot = 1
local i = 1 
foreach type in Two Three Four Five Six {
	local i = `i' + 1
	replace units_tot = `i' if num_apartments == "`type'"
}
gen count_sf = units_tot == 1

*merge m:1 pin using `geo'


collapse (rawsum) count_sf units_tot, by(year_built)

rename (count_sf units_tot)=_improv

*Merging with Census Data and Benchmarking
rename year_built year
gen state = 17 
gen county = 31
merge 1:1 year state county using "${derived}/census_permits_survey/bps_survey", keep(3) nogen
merge 1:1 year  using `commercial', keep(3) nogen
merge 1:1 year  using `condos', keep(3) nogen


gen total_units = units_tot_improv + units_tot_com + units_condo


tw 	(connected count_sf_improv year if year >= 2000 & !mi(count_sf)) ///
	(connected units_1 year if year >= 2000 & !mi(count_sf)), ///
	ytitle("SF Units Built") xtitle("Year Built") ///
	legend(order(1 "County Clerk Data" 2 "Census Building Permits Survey" ) col(1) ring(0) pos(2) size(medium))
	
graph export "${graphics}/sf_benchmark.pdf", replace
	

	tw 	(connected total_units year if year >= 2000 & !mi(count_sf)) ///
	(connected units year if year >= 2000 & !mi(count_sf)), ///
	ytitle("Units Built") xtitle("Year Built") ///
	legend(order(1 "County Clerk Data" 2 "Census Building Permits Survey" ) col(2) size(medium))
	graph export "${graphics}/units_benchmark.pdf", replace

	e
*-------------------------------------------------------------------------------
*Trying with Ferns Data
*-------------------------------------------------------------------------------


import delim "/Users/tylerjacobson/Dropbox/Politics of Housing Segregation/data/cleaned_data/main/new_construction.csv", clear

destring issue_year num_units, replace force

collapse (rawsum) num_units, by(issue_year)
rename issue_year year

gen state = 17 
gen county = 31
merge 1:1 year state county using "${derived}/census_permits_survey/bps_survey", keep(3) nogen

tw 	(connected num_units year if year >= 2000) ///
	(connected units year if year >= 2000 ), ///
	ytitle("Units Built") xtitle("Year Built") ///
	legend(order(1 "County Clerk Data" 2 "Census Building Permits Survey" ) col(1) ring(0) pos(2) size(medium))
