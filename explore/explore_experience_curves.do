*Benchmarking Permits in NYC 


global census  "${dropbox}/development/data/derived/census_permits_survey"
global derived  "${dropbox}/development/data/derived"
global export "${dropbox}/development/figures/exp_curves"
cap mkdir "${export}"
*-------------------------------------------------------------------------------
*Prepping Data
*-------------------------------------------------------------------------------

use "${derived}/nyc/dob_permits_firm_ids", clear

merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3)

gen n = 1 
keep if proposeddwellingunits >= 20

collapse (rawsum) proposeddwellingunits n, by(firm issuance_date council_district)

*Winsorizing Unit Counts
gen units_winsor = proposeddwellingunits
sum proposeddwellingunits, d
replace units_winsor =`r(p99)' if units_winsor > `r(p99)' & !mi(units_winsor)

bys council_district: egen avg_units = mean(proposeddwellingunits)
gen frac_average = proposeddwellingunits/avg_units

*Getting order of project date and number of projects
bys firm (issuance_date): gen order = _n
bys firm (issuance_date): gen projects = _N

*Earliest time in political district
bys firm council_district: egen first_date_district = min(issuance_date)
*First project in district and new district 
gen first_project = first_date_district == issuance_date 
gen new_district = first_date_district == issuance_date & order != 1

*Getting Number of Districts
bys firm: egen districts = sum(new_district)
gen multi_district = districts >= 1 

*Order of Districts
bys firm council_district: gen district_order = _n

*Getting Year
gen year = year(issuance_date)

gen very_large = proposeddwellingunits >= 200
gen large = proposeddwellingunits >= 100

egen firm_id = group(firm)

bys firm: egen first_year = min(year)
gen exp = year - first_year


gen order_under10 = order*(order<= 10)
gen order_over10 = order*(order> 10)
gen over_10 = (order> 10)
gen log_units = log(proposeddwellingunits)
*-------------------------------------------------------------------------------
*Analysis
*-------------------------------------------------------------------------------

reg proposeddwellingunits order_* over_10, r 

binscatter proposeddwellingunits order, line(connect) ///
	ytitle("Number of Units") xtitle("Nth Project")

	
reg log_units order_* over_10, r 
local coef_under10 = round(_b[order_under10], .001)	
local se_under10 = round(_se[order_under10], .001)
local coef_over10 = round(_b[order_over10],.001)	
local se_over10 = round(_se[order_over10],.001)	

binscatter log_units order, line(connect) ///
	ytitle("Number of Units") xtitle("Nth Project") ///
	subtitle(`"Coefficient Below 10: `coef_under10' (`se_under10')"' `"Coefficient Above 10: `coef_over10' (`se_over10')"' , ///
			ring(0) pos(5))
			
reg log_units order_* over_10 if projects >= 15 & order <= 15, r 
local coef_under10 = round(_b[order_under10], .001)	
local se_under10 = round(_se[order_under10], .001)
local coef_over10 = round(_b[order_over10],.001)	
local se_over10 = round(_se[order_over10],.001)	

binscatter log_units order if projects >= 15 & order <= 15, line(connect) ///
	ytitle("Number of Units") xtitle("Nth Project") ///
	subtitle(`"Coefficient Below 10: `coef_under10' (`se_under10')"' `"Coefficient Above 10: `coef_over10' (`se_over10')"' , ///
			ring(0) pos(5))
	
	


	
*Good Spec:
bys firm: egen mean_units = mean(log_units)
gen d_log_units = log_units - mean_units

areg log_units order_* over_10 year , vce(cluster firm_id) absorb(firm)
local coef_under10 = round(_b[order_under10], .001)	
local se_under10 = round(_se[order_under10], .001)
local coef_over10 = round(_b[order_over10],.001)	
local se_over10 = round(_se[order_over10],.001)	

binscatter d_log_units order, line(connect) ///
	ytitle("Log Units Relative to Firm Average") ///
	xtitle("Nth Project") ///
	subtitle(`"Coefficient Below 10: `coef_under10' (`se_under10')"' `"Coefficient Above 10: `coef_over10' (`se_over10')"' , ///
			ring(0) pos(5)) 
			
graph export "${export}/exp_curve_d_log_units.pdf", replace


gen log_order = log(order)
gen log_order_district = log(district_order) 


areg log_units log_order log_order_district year  , vce(cluster firm_id) absorb(firm)


*Checking Whether District Order Still Matters once controlling for total experience
areg log_units order_* over_10 new_district district_order  , absorb(firm ) cluster(firm_id) 

areg proposeddwellingunits order_* over_10 new_district district_order if multi_district == 1 , absorb(firm ) cluster(firm_id) 

*Adding Time Trend
areg log_units order_* over_10 new_district district_order year if multi_district == 1 , absorb(firm ) cluster(firm_id) 

areg proposeddwellingunits order_* over_10 new_district district_order year if multi_district == 1 , absorb(firm ) cluster(firm_id) 


areg log_units order_* over_10 new_district district_order if multi_district == 1 , absorb(firm ) cluster(firm_id) 


reg log_units district_order order_* over_10 new_district if multi_district == 1

binscatter log_units district_order, control(order_* over_10 new_district i.firm_id)
e
*Sensitivitiy to Dropping Two Biggest Firms
areg log_units order_* over_10 new_district i.year if multi_district == 1 & projects <= 50  , absorb(firm ) cluster(firm_id)

areg log_units order_* over_10 new_district i.year if multi_district == 1 & projects <= 40  , absorb(firm ) cluster(firm_id)

		
	
	
areg proposeddwellingunits order_* over_10 new_district i.year, absorb(firm ) r
areg log_units order_* over_10 new_district i.year if multi_district == 1 , absorb(firm ) cluster(firm_id)



areg proposeddwellingunits order_* over_10 new_district i.year, absorb(firm ) cluster(firm_id)
areg large order_* over_10 new_district i.year, absorb(firm ) cluster(firm_id)

binscatter log_units order if multi_district == 1 , control(i.year)
e

binscatter log_units order, control(iyear

binscatter very_large order ///
	if projects >= 15 & inrange(order,1,15), ///
	line(connect) 
	
binscatter large order ///
	if projects >= 15 & inrange(order,1,15), ///
	line(connect) 
	
binscatter proposeddwellingunits order ///
	if projects >= 20 & order<= 20 , ///
	line(connect) 

binscatter frac_average order ///
	if projects >= 20 & order<= 20 , ///
	line(connect) 
	
	e
*Regression 	
reg proposeddwellingunits order ///
	if projects >= 20 & inrange(order,1,20), r 
reg large order ///
	if projects >= 20 & inrange(order,1,20), r 

*Adding New District
reg proposeddwellingunits order new_district ///
	if projects >= 20 & inrange(order,1,20), r 
reg large order new_district ///
	if projects >= 20 & inrange(order,1,20), r 
	
*Adding Year Fixed Effects
areg proposeddwellingunits order new_district ///
	if projects >= 20 & inrange(order,1,20) & multi_district == 1 , r absorb(year)

areg large order  new_district  ///
	if projects >= 20 & inrange(order,1,20) & multi_district == 1, r absorb(year)

areg avg_units order  new_district  ///
	if projects >= 20 & inrange(order,1,20) & multi_district == 1, r absorb(year)

	
	
areg proposeddwellingunits order district_order new_district ///
	if projects >= 20 & inrange(order,1,20) & multi_district == 1 ///
	, r absorb(year)	

areg large order district_order new_district ///
	if projects >= 20 & inrange(order,1,20) & multi_district == 1 ///
	, r absorb(year)	
	
areg large order district_order  ///
	if projects >= 20 & inrange(order,1,20) & multi_district == 1 ///
	, r absorb(year)	
	
*Adding Year Fixed Effects
areg avg_units order new_district ///
	if projects >= 20 & inrange(order,1,20) ///
		& multi_district == 1  ///
	, r absorb(year)
e
	
areg proposeddwellingunits order new_district ///
	if projects >= 10 & inrange(order,1,10) & multi_district == 1 , r absorb(year)
	
		
	
e
reg proposeddwellingunits order if inrange(projects, 8,15) & inrange(order,1,10) 
reg proposeddwellingunits order district_order first_project if inrange(projects, 10,50) 

binscatter proposeddwellingunits order if inrange(projects, 10,50) & inrange(order,1,10) & multi_district == 1, line(connect) 



reg proposeddwellingunits order new_district
areg proposeddwellingunits order new_district i.year if inrange(projects, 10,50) , absorb(firm)

egen firm_id = group(firm)

binscatter proposeddwellingunits order if inrange(projects, 8,20) & inrange(order,1,10) , line(connect) 

sort firm order
tw 	(connect proposeddwellingunits order if firm == "2124213535") ///
	(scatter proposeddwellingunits order if firm == "2124213535" & new_district==1)
