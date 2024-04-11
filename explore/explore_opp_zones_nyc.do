*Exploring NYC QOZs

global data "${dropbox}/development/data"
global output "${dropbox}/development/figures"

*Load In Exposure 
import delim "${data}/derived/nyc_qoz_exposure.csv", clear
xtile frac_qoz_q = frac_qoz, nq(2)
tempfile qoz 
save `qoz'

*Load in Candidate List
import excel  "${data}/raw/nyc_donations/candidate_lists/list2023.xlsx", clear

*Extracting District
gen district = subinstr(C, "City Council District", "",.)
destring district, replace
rename A recipname 
keep recipname district 

replace recipname = subinstr(recipname, "*","",.)
tempfile candidates 
save `candidates'

*Load in Donations Data

import delim "${data}/raw/nyc_donations/city_council_donations.csv", clear bindquote(strict)

gen real_estate = . 
replace real_estate = 1 if strpos(occupation, "real estate") != 0
replace real_estate = 1 if strpos(occupation, "realtor") != 0
replace real_estate = 1 if strpos(occupation, "realty") != 0
replace real_estate = 1 if strpos(occupation, "construction") != 0
replace real_estate = 1 if strpos(occupation, "property") != 0
replace real_estate = 1 if strpos(occupation, "architect") != 0

gen amnt_real_estate = amnt if real_estate == 1

tempfile donations 
save `donations'

foreach year in 2009 2013 2017 2021 2023 {
		
	*Load in Candidate List
	import excel  "${data}/raw/nyc_donations/candidate_lists/list`year'.xlsx", clear

	*Extracting District
	keep if strpos(C, "City Council District")!= 0
	gen district = subinstr(C, "City Council District", "",.)
	destring district, replace
	rename A recipname 
	keep recipname district 

	replace recipname = subinstr(recipname, "*","",.)
	tempfile candidates 
	save `candidates'
	
	use `donations' if election == `year'

	merge m:1 recipname using `candidates'

	collapse (rawsum) amnt amnt_real_estate, by(district)

	merge 1:1 district using `qoz', nogen
	
	gen year = `year'
	tempfile data`year'
	save `data`year''
}

clear 
foreach year in 2009 2013 2017 2021 2023 {
	append using `data`year''
}

drop if mi(frac_qoz)

binscatter amnt frac_qoz, by(year)

bys year: egen total = sum(amnt)
gen frac = amnt/total
bys year: egen total_re = sum(amnt_real_estate)
gen frac_re = amnt_real_estate/total_re

foreach year in 2009 2013 2017 2021 2023 {
	gen frac_qoz_y`year' = frac_qoz if year == `year'
	replace frac_qoz_y`year' = 0 if mi(frac_qoz_y`year')
}
drop frac_qoz_y2017 

gen share_real_estate = amnt_real_estate/amnt

reg frac i.year frac_qoz frac_qoz_y*, r
foreach year in  2009 2013 2017 2021 2023 {
	if `year' == 2017 {
		local coef`year' = 0
		local se`year' = 0 
	}
	if `year' != 2017 {
		local coef`year' = _b[frac_qoz_y`year']
		local se`year' = _se[frac_qoz_y`year']

	}
}


gen post = year >= 2021 
binscatter frac frac_qoz  [w=amnt], by(post)
binscatter amnt frac_qoz  , by(post)

reg frac c.frac_qoz#i.post post frac_qoz,r

binscatter frac_re frac_qoz [w=amnt], by(post)
reg frac_re c.frac_qoz#i.post post frac_qoz [w=amnt],r
reg frac c.frac_qoz#i.post post frac_qoz [w=amnt],r


collapse (rawsum) frac frac_re amnt amnt_real_estate, by(year frac_qoz_q)

tw 	(connect frac year if frac_qoz_q == 1) ///
	(connect frac year if frac_qoz_q == 2), ///
	ytitle("Fraction of Donations") ///
	xtitle("Year") ///
	legend(order(1 "Below Median QOZ Share" 2 "Above Median QOZ Share") ///
	col(1) ring(0) pos(2) size(medium)) ///
	xlabel(2009(2)2023) xline(2018, lcolor(grey%60) lpattern(dash))
graph export "${output}/donation_share_nyc.pdf", replace

tw 	(connect frac_re year if frac_qoz_q == 1) ///
	(connect frac_re year if frac_qoz_q == 2), ///
	ytitle("Fraction of Real Estate Donations") ///
	xtitle("Year") ///
	legend(order(1 "Below Median QOZ Share" 2 "Above Median QOZ Share") ///
	col(1) ring(0) pos(2) size(medium)) ///
	xlabel(2009(2)2023) xline(2018, lcolor(grey%60) lpattern(dash))
graph export "${output}/re_donation_share_nyc.pdf", replace
e
	
	
	
clear 
set obs 5 
gen year = 2009 + 4*(_n-1)
replace year = 2023 if year == 2025
gen coef = . 
gen se = . 
foreach year in  2009 2013 2017 2021 2023 {
	replace coef = `coef`year'' if year == `year'
	replace se = `se`year'' if year == `year'
	
}

gen u_coef = coef + 1.96*se 
gen l_coef = coef - 1.96*se 

tw (connect coef year, color(navy)) ///
	(rcap u_coef l_coef year, color(navy)), ///
	yline(0, lpattern(dash) lcolor(gray%60)) ///
	xline(2018, lpattern(dash) lcolor(gray%60)) ///
	legend(off) ytitle("Coefficient") xtitle("Year")

graph export "${output}/event_study_donations_nyc.pdf", replace
