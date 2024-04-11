
global politics "${dropbox}//Politics of Housing Segregation/data"
global derived "${dropbox}/development/data/derived"


import delim "${politics}/raw_data/permits/Building_Permits.csv", clear
keep id zoning_fee_paid zoning_fee_unpaid
tempfile zoning_fees
save `zoning_fees'

import delim "${politics}/cleaned_data/permits/permits_residential_new.csv", clear
merge 1:1 id using `zoning_fees', keep(3) nogen

gen total_zoning = zoning_fee_paid + zoning_fee_unpaid
gen map = total_zoning > 1000 if !mi(total_zoning)
binscatter map num_units if num_units > 2


collapse (rawsum) num_units, by(issue_year) 
rename issue_year year 
gen state = 17 
gen county = 31
destring year, replace force
merge 1:1 year state county using "${derived}/census_permits_survey/bps_survey", keep(3) nogen

tw (connect num_units year) (connect units year)

gen pct_num_units = num_units/11000
gen pct_units = units/20000

tw (connect pct_num_units year) (connect pct_units year)

corr pct_num_units pct_units
