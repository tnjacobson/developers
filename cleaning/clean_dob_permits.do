*Cleaning Permits Data


global data "${dropbox}/development/data/raw"
global output "${dropbox}/development/data/derived/nyc"
cap mkdir "${output}"
set more off
	clear

*---------------------------------------------------------------------------
*DOB Issuance
*---------------------------------------------------------------------------

*** Import data
	
import delimited "$data/nyc_housing/all_permits/DOB_Permit_Issuance.csv", encoding(ISO-8859-1)

* Keep only New Building (NB) job type
keep if jobtype == "NB"
keep if permittype == "NB"

* Keep only initial permits
keep if filingstatus == "INITIAL"

* Clean issuance date (for universe definition and analysis)
gen issuance_date = date(issuancedate,"MDY")
gen issuance_year = year(issuance_date)

* Keep first issuance
bys bin: gegen min_issuance_date = min(issuance_date)
keep if issuance_date == min_issuance_date


* Destring BIN
destring bin, replace

* Recode borough
gen borocode = .
replace borocode = 1 if borough == "MANHATTAN"
replace borocode = 2 if borough == "BRONX"
replace borocode = 3 if borough == "BROOKLYN"
replace borocode = 4 if borough == "QUEENS"
replace borocode = 5 if borough == "STATEN ISLAND"

drop borough
rename borocode borough

label define borough_label 1 "Manhattan" 2 "Bronx" 3 "Brooklyn" 4 "Queens" 5 "Staten Island"
label values borough borough_label

* Create BBL codes

* Fix stray typos in block/lot codes (note: first fixes a hidden-character issue)
replace block = "06534" if block == "O6534"
replace lot = "28" if lot == "...28"

* Destring block lot, now that it is repaired
destring block lot, replace

* Drop if missing component of BBL code
drop if missing(borough) | missing(block) | missing(lot)

tostring borough, gen(boro)
tostring block, gen(block_)
tostring lot, gen(lot_)

replace block_ = "0"+block_ if length(block_)<5
replace block_ = "0"+block_ if length(block_)<5
replace block_ = "0"+block_ if length(block_)<5
replace block_ = "0"+block_ if length(block_)<5

replace lot_ = "0"+lot_ if length(lot_)<4
replace lot_ = "0"+lot_ if length(lot_)<4
replace lot_ = "0"+lot_ if length(lot_)<4

gen bbl = boro+block_+lot_
destring bbl, replace

drop block_ lot_ boro

format bbl %18.0f

*Keeping Earliest Job (Only a Handful will be deleted)
bys job (issuance_date) : keep if _n == 1 

foreach var in ownersbusinessname permitteesbusinessname {
	gen has_`var' = !mi(`var')
}



save "${output}/dob_permits", replace

*---------------------------------------------------------------------------
*DOB Now
*---------------------------------------------------------------------------
import delim "${data}/nyc_housing/DOB_NOW__Build___Approved_Permits_20240129.csv", clear

* Keep only New Building (NB) job type
*keep if jobtype == "NB"
	
* Keep only initial permits
keep if filingreason == "Initial Permit"

* Recode borough
gen borocode = .
replace borocode = 1 if borough == "MANHATTAN"
replace borocode = 2 if borough == "BRONX"
replace borocode = 3 if borough == "BROOKLYN"
replace borocode = 4 if borough == "QUEENS"
replace borocode = 5 if borough == "STATEN ISLAND"

tostring borocode, gen(boro)
tostring block, gen(block_)
tostring lot, gen(lot_)

replace block_ = "0"+block_ if length(block_)<5
replace block_ = "0"+block_ if length(block_)<5
replace block_ = "0"+block_ if length(block_)<5
replace block_ = "0"+block_ if length(block_)<5

replace lot_ = "0"+lot_ if length(lot_)<4
replace lot_ = "0"+lot_ if length(lot_)<4
replace lot_ = "0"+lot_ if length(lot_)<4

gen bbl = boro+block_+lot_
destring bbl, replace

drop block_ lot_ boro

format bbl %18.0f

* Clean issuance date (for universe definition and analysis)
gen issuance = clock(issueddate,"MDY hms")
gen issuance_date = dofc(issuance)
gen issuance_year = year(issuance_date)
drop issuance

format issuance_date %td

bys bbl (issuance_date): keep if _n == 1 


save "${output}/dob_permits_now", replace

