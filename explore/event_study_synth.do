*Make Analysis File

global project "${dropbox}/nyc_charter"
global derived "${project}/data/derived"
global output "${project}/output/event_studies"
cap mkdir "${output}"

*-------------------------------------------------------------------------------
*Graphing Using Per Capita Weights
*-------------------------------------------------------------------------------


use "${derived}/combined_county_panel", clear 
keep if pop_rank <= 50


gen nyc = pop_rank == 1 

gen log_units_pc = log(units_rep_pc)

local outcome log_units_rep_pc
#replace log_units_rep_pc = log(units_rep_pc*1000)

binscatter `outcome' year [w=pop1980], by(nyc) discrete line(connect) ///
	xtitle("Year") ///
	legend(order(1 "Average of 50 Largest Counties" 2 "NYC") ///
	size(medium) col(1) ring(0) pos(2)) 
	
e
graph export "${output}/binscatter_`outcome'.pdf", replace

forv year = 1980/2000 {
	gen treat_`year' = (pop_rank == 1 & year == `year')
}

drop treat_1989 

areg `outcome' i.year treat_*  [aw = pop1980] , absorb(area_fips) vce(cluster area_fips)

forv year = 1980/2000 {
	if `year' != 1989 {
		local te_`year'  = _b[treat_`year']
		local se_`year'  = _se[treat_`year']

	}
	if `year' == 1989 {
		local te_`year'  = 0
		local se_`year' = 0 
	}
}

gen treat_post = nyc == 1 & inrange(year, 1990, 1995)
gen pre = year <= 1989
drop if year > 1995
areg units_rep_pc i.year treat_post, absorb(area_fips) vce(cluster area_fips)


clear 
set obs 21
gen year = 1979 + _n

gen te = . 
gen se = . 

forv year = 1980/2000 {
	replace te = `te_`year'' if year == `year'
	replace se = `se_`year'' if year == `year'

}

gen u_te = te + 1.96*se 
gen l_te = te - 1.96*se 

tw (connect te year, color(navy)) ///
	(line u_te year, color(navy) lpattern(dash)) ///
	(line l_te year, color(navy) lpattern(dash)), ///
	yline(0, lpattern(dash) lcolor(grey%60)) ///
	xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
	legend(off)
	
graph export "${output}/es_`outcome'.pdf", replace

e


use "${derived}/combined_county_panel", clear 
keep if pop_rank <= 50


gen nyc = pop_rank == 1 

gen log_units_1989 = log_units_rep if year == 1989

keep if inrange(year, 1990, 1995) 
