*COmparing permitting lenght

global project "${dropbox}/development"
global data "${project}/data/derived"

use "${data}/wluri/WRLURI_01_15_2020.dta", clear


use "${data}/wluri/WHARTON LAND REGULATION DATA_1_24_2008", clear
bys id: keep if _n == 1 
keep id state name time_sfu time_mfu
rename (state name time_sfu time_mfu)=_2008

rename (q16b118 q17b118) (time_mfu_2020_by_right time_mfu_2020_rezone)


import delim "/Users/tylerjacobson/Desktop/U.S._Field_Production_of_Crude_Oil.csv" ,clear 

drop if _n <= 5

rename v1 year 
rename v2 total_barrels
destring year total_barrels, replace 
tempfile total 
save `total'

import delim using "https://revenuedata.doi.gov/downloads/calendar_year_production.csv", clear

keep if  product == "Oil (bbl)" 

gen count = 1 

collapse (rawsum) volume, by(calendaryear)

rename calendaryear year 
rename volume federal_barrels  
replace federal_barrels  = federal_barrels  /1000

merge 1:1 year using `total', keep(3)


gen fed_share = federal_barrels/total_barrels

tw (connect fed_share year)

tw (connect federal_barrels year)



*-------------------------------------------------------------------------------
*Fraction of Land By State
*-------------------------------------------------------------------------------
import excel "/Users/tylerjacobson/Dropbox/env review/data/raw/eis_state_crude_data.xls", sheet("Data 1") clear

rename A date 
rename AO total_california
rename AA total_new_mexico
rename AB total_texas
rename D total_florida 
rename E total_new_york
rename F total_pennsylvania 
rename G total_virginia
rename H total_west_virginia
rename J total_illinois 
rename K total_indiana 
rename L total_kansas
rename M total_kentucky
rename N total_michigan
rename O total_missouri
rename P total_nebraska
rename Q total_north_dakota
rename R total_ohio 
rename S total_oklahoma
rename T total_south_dakota 
rename U total_tennessee 
rename W total_alabama 
rename X total_arkansas 
rename Y total_louisiana 
rename Z total_mississippi 
rename AE total_colorado 
rename AF total_idaho 
rename AG total_montana 
rename AH total_utah 
rename AI total_wyoming
rename AK total_alaska_field 
rename AL total_alaska_south
rename AM total_alaska_north
rename AN total_arizona
rename AP total_nevada

keep if _n >= 4 

destring total*, replace

gen td = date(date, "DMY")

gen year = year(td)

collapse (rawsum) total*, by(year)
reshape long total_, i(year) j(state) string
drop if total_ == 0 

replace state = subinstr(state, "_"," ",.)
replace state = "alaska" if strpos(state, "alaska")!= 0

collapse (rawsum) total, by(state year)


tempfile state_data 
save `state_data'

import delim using "https://revenuedata.doi.gov/downloads/calendar_year_production.csv", clear

keep if  product == "Oil (bbl)"  & landclass == "Federal"

rename calendaryear year 
rename volume federal_barrels  
replace federal_barrels  = federal_barrels  /1000

replace state = strlower(state)

collapse (rawsum) federal_barrels, by(state year)

merge 1:1 state year using `state_data'

keep if inrange(year, 2003, 2023)
gen frac_fed = federal_barrels/total_

binscatter frac_fed year, line(connect) discrete


tw (connect frac_fed year if state == "texas")
tw (connect frac_fed year if state == "california")
tw (connect frac_fed year if state == "wyoming")
tw (connect frac_fed year if state == "new mexico")
tw (connect frac_fed year if state == "nevada")
tw (connect frac_fed year if state == "north dakota")
tw (connect frac_fed year if state == "wyoming")


import delim using "https://revenuedata.doi.gov/downloads/calendar_year_revenue.csv", clear

keep if  mineralleasetype == "Oil & Gas"  & landclass == "Federal" & revenuetype == "Bonus"

collapse (rawsum) revenue, by(state calendaryear)

tw (connect revenue calendaryear if state == "California"), xlabel(2000(2)2020)
tw (connect revenue calendaryear if state == "Texas"), xlabel(2000(2)2020)
tw (connect revenue calendaryear if state == "New Mexico"), xlabel(2000(4)2020)
tw (connect revenue calendaryear if state == "Alaska"), xlabel(2000(4)2020)
tw (connect revenue calendaryear if state == "Colorado"), xlabel(2000(4)2020)
tw (connect revenue calendaryear if state == "Wyoming"), xlabel(2000(4)2020)
tw (connect revenue calendaryear if state == "Montana"), xlabel(2000(4)2020)
