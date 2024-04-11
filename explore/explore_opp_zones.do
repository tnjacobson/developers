
**Explore Housing Data 
global data "${dropbox}/development/data/derived"
global donations "${dropbox}/Politics of Housing Segregation/data/cleaned_data/alderman_elections/campaign_donations"
global export "${dropbox}/development/figures"


*Prep QOZs
import delim "${dropbox}/Politics of Housing Segregation/data/cleaned_data/opp_zones/opp_zones.csv" ,clear
drop opp_zone_elig 

gen opp_zone_elig = poverty > .30 | unemp > .2 | median_income < 38000
replace opp_zone_elig = 1 if opp_zone == 1 
binscatter opp_zone opp_zone_elig median_income, line(connect)

tempfile tracts 
save `tracts'

import delim "${data}/rezoning/zoning_changes.csv", clear
gen pd = pd_num != "0"

gen year = substr(final_date_clerk, 7,4)
destring year, replace 

gen tract_temp = substr(tract,6,6)
destring tract_temp, replace 
drop tract
rename tract_temp tract

gen count = 1 
drop if mi(year)
collapse (rawsum) count pd, by(tract year)

merge m:1 tract using `tracts', nogen keep(2 3)
replace year = 2010 if mi(year)
xtset tract year 
tsfill, full 

replace count = 0 if mi(count)


foreach var in opp_zone opp_zone_elig median_income {
	bys tract: egen temp = max(`var')
	replace `var' = temp if mi(`var')
	drop temp
}

binscatter opp_zone_elig opp_zone median_income if year >= 2021 & median_income < 50000 , line(connect) 




gen has_rezone = count > 0 
replace opp_zone_elig = 1 if opp_zone == 1 
binscatter count year if opp_zone_elig == 1 & year > 2010, by(opp_zone) line(connect) 


gen treated = opp_zone == 1 & year >= 2018
forvalues year = 2011/2023 {
	gen opp_zone_y`year' = opp_zone == 1 & year == `year'
}
drop opp_zone_y2017

reg count i.year i.tract opp_zone_y* if opp_zone_elig , r 
forvalues year = 2011/2023 {
	if `year' == 2017 {
		local coef_`year' = 0
		local se_`year' = 0

	}
		if `year' != 2017 {
	local coef_`year' = _b[opp_zone_y`year']
	local se_`year' = _se[opp_zone_y`year']
		}
}
preserve
clear 
set obs 13 
gen year = _n + 2010
gen coef = . 
gen se = . 
forvalues year = 2011/2023 {
	replace coef = `coef_`year'' if year == `year'
	replace se = `se_`year'' if year == `year'
}

gen u_coef = coef + 1.96*se 
gen l_coef = coef - 1.96*se 

tw (connect coef year, color(navy)) ///
	( rcap u_coef l_coef year, color(navy)), ///
	yline(0,lpattern(dash) lcolor(grey%60)) ///
	xline(2018.5,lpattern(dash) lcolor(grey%60))
restore
e
collapse (rawsum) pd count, by(opp_zone opp_zone_elig year)
drop if year == 2010

tw 	(connect count year if opp_zone == 1 & opp_zone_elig == 1) ///
	(connect count year if opp_zone == 0 & opp_zone_elig == 1) 


gen temp = count if year == 2017 
bys opp_zone_elig opp_zone: egen count_2017 = max(temp)
gen ch_2017 = count/count_2017

tw 	(connect ch_2017 year if opp_zone == 1 & opp_zone_elig == 1) ///
	(connect ch_2017 year if opp_zone == 0 & opp_zone_elig == 1)
	
tw 	(connect pd year if opp_zone == 1 & opp_zone_elig == 1) ///
	(connect pd year if opp_zone == 0 & opp_zone_elig == 1)
	
	
	
import delim "${data}/housing/housing_construction.csv", clear
destring tract units year_built, replace force
gen count = 1 
drop if mi(year_built)
drop if mi(units)
gen count10 = units > 10
gen count50 = units > 50
gen count100 = units > 100


collapse (rawsum) count* units, by(tract year_built)
rename year_built year

merge m:1 tract using `tracts', nogen keep(2 3)
replace year = 2010 if mi(year)
xtset tract year 
tsfill, full 
foreach var of varlist count* units {
	replace `var' = 0 if mi(`var')
}

foreach var in opp_zone opp_zone_elig median_income {
	bys tract: egen temp = max(`var')
	replace `var' = temp if mi(`var')
	drop temp
}





collapse (rawsum) units count*, by(opp_zone opp_zone_elig year)
drop if year == 2024
drop if year <= 2011
tw 	(connect count year if opp_zone == 1 & opp_zone_elig == 1) ///
	(connect count year if opp_zone == 0 & opp_zone_elig == 1)

	tw 	(connect count10 year if opp_zone == 1 & opp_zone_elig == 1) ///
	(connect count10 year if opp_zone == 0 & opp_zone_elig == 1)
e	
	
tw 	(connect units year if opp_zone == 1 & opp_zone_elig == 1) ///
	(connect units year if opp_zone == 0 & opp_zone_elig == 1)
	
