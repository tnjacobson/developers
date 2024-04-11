**Correlation between Donations and Housing

**Explore Housing Data 

global data "${dropbox}/development/data/derived"
global donations "${dropbox}/Politics of Housing Segregation/data/cleaned_data/alderman_elections/campaign_donations"
global export "${dropbox}/development/figures"

*Cleaning Donations Data
use "${donations}/ward_year_donations", clear

keep ward year amount amount_real_estate 
reshape wide amount*, i(ward) j(year)
tempfile donations 
save `donations'


import delim "${data}/housing/housing_construction", clear
rename ward2015 ward

destring year_built units, replace force
keep if inrange(year_built, 2015, 2023)
gen election = 2015 if inrange(year_built, 2015, 2019)
replace election = 2019 if inrange(year_built, 2020, 2023)

gen pd = substr(zone_class2023,1,2) == "PD"
gen ch = zone_class2023 != zone_class2012
drop if mi(units)
gen ch_pd = ch == 1 | pd == 1 

gen count = 1 
gen count_medium = inrange(units, 10,100) 
gen units_medium = units if inrange(units, 10,100) 

gen count50 = units >= 50 
gen count100 = units>= 100

foreach var of varlist units* count*  {
	gen `var'_chpd1 = `var' if ch_pd == 1 
	gen `var'_chpd0 = `var' if ch_pd == 0 
}

collapse (rawsum) units* count*, by(ward election) 

foreach var of varlist units* count*  {
	replace `var' = 0 if mi(`var')
}


destring ward, replace force

merge m:1 ward using `donations', keep(1 3) nogen
e

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
	