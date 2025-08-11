*Exploring Chads Data

/*
1521: General contractors single family residential 
1522: General contractors multifamily residential
1531: Operative Builder: i.e. not a contractor 
*/





global raw_data "${dropbox}/development/data/goolsbee_syverson/housing_construction"
global derived "${dropbox}/development/data/derived"
global env_data "${dropbox}/development/data/raw/env_review"


import delim "${env_data}/laws.csv", clear varnames(1)
keep state datepassed 
replace datepassed = "1970" if state == "California"
destring datepassed, replace

replace state = strlower(state)
tempfile env_review 
save `env_review'


 
foreach year in 1977 1982 1987 1992  {
	append using "${raw_data}/`year'_1531"
	append using "${raw_data}/`year'_1521"	
}


append using "${raw_data}/1972_1521_1531"

collapse (rawsum) totEmp NetConstrValue InterCost asset_end, by(state year)

gen ve = (NetConstrValue-InterCost) /totEmp

tw 	(connect ve year if state == "California") ///
	(connect ve year if state == "Texas")
	
merge m:1 state using `env_review', keep(1 3) nogen

gen treat = !mi(datepassed)

binscatter ve year , by(treat) line(connect) legend(order(1 "No Env Review" 2 "Env Review"))



import excel "${env_data}/HPI_AT_BDL_state.xlsx", clear
drop if _n <= 6 
rename A state 
rename B abbr 
rename C fips 
rename D year 
rename F HPI

keep state abbr fips year HPI

destring HPI year, replace force

merge m:1 state using `env_review', keep(1 3)
gen treat = !mi(datepassed)


binscatter HPI year, by(treat) legend(order(1 "No Env Review" 2 "Env Review")) ///
line(connect)

gen treated = treat == 1 & year>= datepassed

areg HPI treated i.year, absorb(state)

gen group = . 
replace group = 0 if treat == 0 
replace group = 1 if datepassed <= 1975
replace group = 2 if datepassed > 1975 & datepassed <= 1991


binscatter HPI year, by(group) line(connect)




*Looking at Rollout of State Laws
use "${env_data}/landuse", clear
drop state
statastates, abbrev(stateabbrev) nogen 
replace state_name = strlower(state_name)
rename state_name state 

merge m:1 state  using `env_review', keep(1 3)

gen treat = !mi(datepassed)

gen group = . 
replace group = 0 if treat == 0 
replace group = 1 if datepassed <= 1975
replace group = 2 if datepassed > 1975 & datepassed <= 1991


binscatter documentcount year if keyword == "land use", by(treat) line(connect) discrete xline(1970)
binscatter documentcount year if keyword == "land use", by(group) line(connect) discrete xline(1970)
binscatter zoningdocumentcount year , by(treat) line(connect) discrete xline(1970)
binscatter permitsPerStock year , by(treat) line(connect) discrete xline(1970)
binscatter documentcount year if inrange(year, 1960,2000), by(group) line(connect) discrete xline(1970)
 
gen cases_unit = documentcount/permit

binscatter cases_unit year if keyword == "land use", by(treat) line(connect) discrete xline(1970) 

collapse (rawsum) documentcount, by(year treat)

keep if inrange(year, 1960,2010)
tw (connect documentcount year if treat == 0 ) ///
	(connect documentcount year if treat == 1 )
e
binscatter total_annual_docs year if inrange(year, 1960,2000), by(group) line(connect) discrete xline(1970)

gen frac_land_use = documentcount/total_annual_docs

binscatter frac_land_use year, by(group) line(connect) discrete xline(1970)

gen treated = treat == 1 & year>= datepassed

gen cases_pop = documentcount/valueCount

areg documentcount treated i.year, absorb(state) vce(cluster state)


gen temp = documentcount if year == 1970 
bys state: egen base = max(temp)
gen r_documentcount = documentcount/base
sort year
tw 	(connect r_documentcount year if state == "new york") ///
	(connect r_documentcount year if state == "new jersey"), ///
	xline(1973, lpattern(dash) lcolor(blue%60)) ///
	xline(1987, lpattern(dash) lcolor(orange%60))

	
	
collapse (mean) documentcount, by(year treat) 

gen temp = documentcount if year == 1970 
bys treat: egen base = max(temp)
gen r_documentcount = documentcount/base
keep if inrange(year, 1960, 2010)
sort year
tw 	(connect documentcount year if treat == 0) ///
	(connect documentcount year if treat == 1) 
	
tw 	(connect r_documentcount year if treat == 0) ///
	(connect r_documentcount year if treat == 1) 
	e

gen log_document = log(documentcount)

tw 	(connect log_document year if treat == 0) ///
	(connect log_document year if treat == 1) 
