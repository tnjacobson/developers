*Clean Job Applications
*NYC DOB publishes datasets on jobs, which appear to be grouped permit information 

global data "${dropbox}/development/data/raw"
global output "${dropbox}/development/data/derived/nyc"
cap mkdir "${output}"
set more off
	clear
	
	
*---------------------------------------------------------------------------
*DOB Issuance
*---------------------------------------------------------------------------
import delimited "$data/nyc_housing/dob_jobs/DOB_Job_Application_Filings_20240205", encoding(ISO-8859-1) clear

*Only Keep New Building or Major Alterations 
keep if jobtype == "NB" | jobtype == "A1"


*Cleaning Units
replace existingdwellingunits = "0" if jobtype == "NB"
keep if !mi(proposeddwellingunits)

destring existingdwellingunits proposeddwellingunits, replace force
replace existingdwellingunits = 0 if mi(existingdwellingunits)
gen new_units = proposeddwellingunits - existingdwellingunits

*Cleaning Date
gen assigned_date = date(assigned, "MDY")
gen assigned_year = year(assigned_date)

*Cleaning bbl
gen borocode = ""
replace borocode = "1" if borough == "MANHATTAN"
replace borocode = "2" if borough == "BRONX"
replace borocode = "3" if borough == "BROOKLYN"
replace borocode = "4" if borough == "QUEENS"
replace borocode = "5" if borough == "STATEN ISLAND"

drop if  mi(borocode, block, lot)

* Fix stray typos in block/lot codes (note: first fixes a hidden-character issue)
replace block = "06534" if block == "O6534"
drop if block == "-1948"
drop if lot == "23,24"
replace lot = "28" if lot == "...28"

gen bbl = borocode + block + lot


destring bbl, replace 

format bbl %18.0f

bys job (assigned_date): keep if _n == 1

save "${output}/dob_jobs", replace
