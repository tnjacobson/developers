
**Explore Housing Data 
global data "${dropbox}/development/data/derived"
global donations "${dropbox}/Politics of Housing Segregation/data/cleaned_data/alderman_elections/campaign_donations"
global export "${dropbox}/development/figures"

*Cleaning Donations Data
use "${donations}/ward_year_donations", clear

*Reshape to Be at Ward Year Level
rename year election
keep ward election amount amount_real_estate 
tempfile donations 
save `donations'

*Load in Constructions
import delim "${data}/housing/housing_construction", clear
rename ward2015 ward
destring year_built units ward, replace force

*Restrict to Years using 2015 Maps
keep if inrange(year_built, 2011, 2023)

*Keep By Election
gen election = . 
replace election = 2011 if inrange(year_built, 2011, 2014)
replace election = 2015 if inrange(year_built, 2015, 2018)
replace election = 2019 if inrange(year_built, 2019, 2023)

*See if required a PD or a zoning change
gen pd = substr(zone_class2023,1,2) == "PD"
gen ch = zone_class2023 != zone_class2012
drop if mi(units)
gen ch_pd = ch == 1 | pd == 1 

*Count number of projects, medium proejcts
gen count = 1 
gen count_medium = inrange(units, 10,100) 
gen units_medium = units if inrange(units, 10,100) 
gen count50 = units >= 50 
gen count100 = units>= 100

foreach var of varlist units* count*  {
	gen `var'_chpd1 = `var' if ch_pd == 1 
	gen `var'_chpd0 = `var' if ch_pd == 0 
}
*Collapse and Merge
collapse (rawsum) units* count*, by(ward election) 
merge 1:1 ward election using `donations', keep(1 2 3) nogen

*Replace units and amounts with 0 if need be
foreach var of varlist units* count*  {
	replace `var' = 0 if mi(`var')
}

*Subtract real estate
gen amount_other = amount - amount_real_estate

*Take Logs (approximate using asinh)
foreach var in units amount amount_real_estate amount_other {
	gen log_`var' = asinh(`var')
	sum `var'
	gen std_`var' = (`var'-`r(mean)')/`r(sd)'
}

replace amount_real_estate = amount_real_estate/1000
replace amount_other = amount_other/1000
foreach y in units units_chpd0 units_chpd1 {
	reg `y' amount_other amount_real_estate if inrange(election, 2015, 2019), r 
	local c_`y'_other = _b[amount_other]
	local se_`y'_other = _se[amount_other]
	local c_`y'_real_estate = _b[amount_real_estate]
	local se_`y'_real_estate = _se[amount_real_estate]
}


*Graphing Code
clear 
set obs 3 
gen place = _n 
gen y = ""
replace y = "units" if place == 1
replace y = "units_chpd1" if place == 2
replace y = "units_chpd0" if _n == 3
gen x = "real_estate"

expand 2, gen(temp)
replace x = "other" if temp == 1
drop temp 
gen coef = . 
gen se = . 
foreach y in units units_chpd0 units_chpd1 {
	foreach x in real_estate other {
		replace coef = `c_`y'_`x'' if "`x'" == x & y == "`y'"
		replace se = `se_`y'_`x'' if "`x'" == x & y == "`y'"

	}
}
gen u_ci = coef + 1.96*se
gen l_ci = coef - 1.96*se

replace place = place + .05 if x == "other"
replace place = place - .05 if x == "real_estate"

tw 	(scatter coef place if x == "real_estate", color(navy)) ///
	(rcap u_ci l_ci place if x == "real_estate", color(navy)) ///
	(scatter coef place if x == "other", color(maroon)) ///
	(rcap u_ci l_ci place if x == "other", color(maroon)), ///
	legend(ring(0) pos(1) col(1) order(1 "Real Estate Donations" 3 "Other Donations" ) size(medium)) ///
	xlabel(1 "Units Built" 2  "Rezoned Units" 3 "Units By Right" ) ///
	xtitle("") ytitle("Coefficient (Units per $1000)") ///
	yline(0,lpattern(dash) lcolor(grey%50)) ///
	xscale(range(.8 3.2))

	graph export "${export}/coef_plot_donations_units.pdf", replace 


e

reg units_chpd1 amount_other amount_real_estate if election == 2015
reg units_chpd0 amount_other amount_real_estate if election == 2015
reg count50 amount_other amount_real_estate if election == 2015
reg count100 amount_other amount_real_estate if election == 2015


binscatter units amount_real_estate
binscatter units amount_other, control(amount_real_estate)
reg amount_other units amount_real_estate

gen amount_r = . 
replace amount_r = amount_real_estate2015 if election == 2015
replace amount_r = amount_real_estate2019 if election == 2019

gen frac_real_estate2015 = amount_real_estate2015/amount2015
gen frac_real_estate2019 = amount_real_estate2019/amount2019

replace amount_real_estate2015 =  amount_real_estate2015 / 1000
replace amount_real_estate2019 =  amount_real_estate2019 / 1000


reg amount_real_estate2015 units_chpd1 units_chpd0 if election == 2015
reg amount_real_estate2019 units_chpd1 units_chpd0 if election == 2019

tw (scatter  units_chpd1 amount_real_estate2019 if election == 2019) ///
	(scatter  units_chpd0  amount_real_estate2019 if election == 2019)


tw 		(scatter amount_real_estate2015 units_chpd1) ///
	 (scatter amount_real_estate2015 units_chpd0)
	
	 
tw scatter units amount_real_estate2015




binscatter units_chpd1 units_chpd0 amount_real_estate2015, ///
	ytitle("Units Built 2015-2019") ///
	xtitle("Donations from Real Estate Sector in 2015 Cycle") ///
	legend(order(1 "Recent Zoning Change or PD Status" 2 "No Zoning Change or PD Status") ///
	ring(0) pos(11) col(1) size(medium))

tw 		(scatter units_chpd1 amount_real_estate2015 if election == 2015 ) ///
		(scatter units_chpd0 amount_real_estate2015 if election == 2015 ), ///
	ytitle("Units Built 2015-2019") ///
	xtitle("Donations from Real Estate in 2015 Cycle") ///
	legend(order(1 "Recent Zoning Change or PD Status" 2 "No Zoning Change or PD Status") ///
	ring(0) pos(11) col(1) size(medium))
		

tw 		(scatter count50_chpd1 frac_real_estate2015 ) ///
		(scatter count50_chpd0 frac_real_estate2015 ), ///
	ytitle("Units Built 2015-2019") ///
	xtitle("Frac. Donations from Real Estate in 2015 Cycle") ///
	legend(order(1 "Recent Zoning Change or PD Status" 2 "No Zoning Change or PD Status") ///
	ring(0) pos(11) col(1) size(medium))
	

tw 		(scatter units_medium_chpd1 frac_real_estate2015 ) ///
		(scatter units_medium_chpd0 frac_real_estate2015 ), ///
	ytitle("Units Built in Medium Buildings 2015-2019") ///
	xtitle("Frac. Donations from Real Estate in 2015 Cycle") ///
	legend(order(1 "Recent Zoning Change or PD Status" 2 "No Zoning Change or PD Status") ///
	ring(0) pos(11) col(1) size(medium))


reg count_medium_chpd1 amount_real_estate2015
reg count_medium_chpd0 amount_real_estate2015
reg units_medium_chpd1 amount_real_estate2015 amount_real_estate2019
reg units_medium_chpd0 amount_real_estate2015



tw 		(scatter units_chpd1 frac_real_estate2015 ) ///
		(scatter units_chpd0 frac_real_estate2015 ), ///
	ytitle("Units Built 2015-2019") ///
	xtitle("Frac. Donations from Real Estate in 2015 Cycle") ///
	legend(order(1 "Recent Zoning Change or PD Status" 2 "No Zoning Change or PD Status") ///
	ring(0) pos(11) col(1) size(medium))
	