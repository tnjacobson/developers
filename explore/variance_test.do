*Testing Variance of Outcomes

global project "${dropbox}/nyc_charter"
global derived "${project}/data/derived"
global output "${project}/output/event_studies"
cap mkdir "${output}"


*-------------------------------------------------------------------------------
*Graphing Using Per Capita Weights
*-------------------------------------------------------------------------------


use "${derived}/combined_county_panel", clear 
keep if pop_rank <= 50
gen log_units_pc = log(units_rep_pc)

local outcome log_units_rep

sum `outcome' if year <= 1989
local mean = `r(mean)'
collapse (sd) `outcome' (mean) mean_`outcome' = `outcome' , by(year)

gen norm = `outcome'/abs(mean_`outcome')
tw (connect norm year), ///
ytitle("Standard Deviation/Pre-Period Mean") ///
xtitle("Year")  
graph export "${output}/variance_`outcome'.pdf", replace
