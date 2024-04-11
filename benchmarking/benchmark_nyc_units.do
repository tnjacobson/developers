*Benchmarking Permits in NYC 


global census  "${dropbox}/development/data/derived/census_permits_survey"
global derived  "${dropbox}/development/data/derived"
global export "${dropbox}/development/figures/nyc"
use "${census}/bps_survey", clear

gen nyc = . 
replace nyc = 1 if state == 36 & inlist(county, 5,47,61,81,85)
keep if nyc == 1 
collapse (rawsum) units, by(nyc year)

tw (connect units year)

rename units census_units

tempfile census 
save `census'



use "${derived}/nyc/dob_permits", clear

merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3)

collapse (rawsum) proposeddwellingunits, by(issuance_year)

rename issuance_year year 

merge 1:1 year using `census', keep(3)

tw (connect proposeddwellingunits year) ///
(connect census_units year), ///
ytitle("Permitted Units") ///
xtitle("Year") ///
legend(order(1 "NYC Data" 2 "Census Survey") col(1) ring(0) pos(11) size(medium))

graph export "${export}/benchmark_nyc_census_permits.pdf", replace


*-------------------------------------------------------------------------------
*Exploring Match
*-------------------------------------------------------------------------------

use "${derived}/nyc/dob_jobs", clear 
keep if jobtype == "NB"
rename assigned_year jobs_year
keep job jobs_year proposeddwellingunits

tempfile jobs
save `jobs'

use "${derived}/nyc/dob_permits", clear
keep if inrange(issuance_year,2000,2022)

merge m:1 job using `jobs'

gen match = _merge == 3 

binscatter match issuance_year if issuance_year >2000 , line(connect) discrete
binscatter match jobs_year if jobs_year >2000 , line(connect) discrete



