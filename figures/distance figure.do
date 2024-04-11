*Benchmarking Permits in NYC 


global census  "${dropbox}/development/data/derived/census_permits_survey"
global derived  "${dropbox}/development/data/derived"
global raw "${dropbox}/development/data/raw"
global export "${dropbox}/development/figures/nyc_charter"
cap mkdir "${export}"


*-------------------------------------------------------------------------------
*BBL 
*-------------------------------------------------------------------------------

use "${raw}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear

gen county = . 

replace county = 5 if Borough == "BX"
replace county = 47 if Borough == "BK"
replace county = 61 if Borough == "MN"
replace county = 81 if Borough == "QN"
replace county = 85 if Borough == "SI"



keep BoroCode Block Lot BBL Tract2010 county
rename (BoroCode Block Lot BBL Tract2010) (boro block lot bbl tract)

destring tract, replace 

isid bbl

replace tract = tract*100 if tract<1000

gen str3 county_str = string(county, "%03.0f")
gen str6 tract_str = string(tract, "%06.0f")

* Concatenate the strings to form the GEOID
gen geoid = "36" + county_str + tract_str

keep geoid bbl 
tempfile bbls 
save `bbls'

*-------------------------------------------------------------------------------
*Centroids
*-------------------------------------------------------------------------------
import delim "${derived}/tract_centroid_distances", clear 

gen county = . 

replace county = 5 if boro_name == "Bronx"
replace county = 47 if boro_name == "Brooklyn"
replace county = 61 if boro_name == "Manhattan"
replace county = 81 if boro_name == "Queens"
replace county = 85 if boro_name == "Staten Island"

replace ct2010 = ct2010*100 if ct2010<1000

gen str3 county_str = string(county, "%03.0f")
gen str6 tract_str = string(ct2010, "%06.0f")

* Concatenate the strings to form the GEOID
gen geoid = "36" + county_str + tract_str

destring distance, replace force 

bys geoid (distance): keep if _n == 1 

isid geoid

tempfile centroids 
save `centroids'
*-------------------------------------------------------------------------------
*Prepping Data
*-------------------------------------------------------------------------------

use "${derived}/nyc/dob_permits_firm_ids", clear

merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3) nogen

merge m:1 bbl using `bbls', keep(1 3) 


keep if inrange(issuance_year, 2010, 2020)
gen projects = 1 
gen large_projects = proposeddwellingunits >= 10

gen sf_share = proposeddwellingunits == 1 
collapse (rawsum) projects large_projects ///
	proposeddwellingunits (mean) avg_units = proposeddwellingunits sf_share, ///
by(geoid)

merge 1:1 geoid using `centroids'

foreach var in projects large_projects proposeddwellingunits {
	replace `var' = 0 if mi(`var')
}

keep if _merge != 1 

gen l_avg_units = log(avg_units)
replace distance = distance/1000
reg l_avg_units distance i.boro_code, r
local slope = round(_b[distance],.001)
local se = round(_se[distance],.001)

binscatter l_avg_units distance , control(i.boro_code) ///
xtitle("Distance to Border (1000ft)") ///
ytitle("Log Average Project Size") ///
text(1.6 .4 "Slope: `slope' (`se')")

graph export "${export}/l_avg_units_distance.pdf", replace 
e

gen l_distance = log(distance)
reg l_avg_units distance i.boro_code, r

gen has_units = proposeddwellingunits > 0 

gen log_units = log(proposeddwellingunits)
binscatter large_projects distance, control(i.boro_code)

reg large_projects distance i.boro_code , r 
reg avg_units distance i.boro_code , r 
reg proposeddwellingunits distance i.boro_code  , r 

