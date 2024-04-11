*Event Study for Opportunity Zones
global data "${dropbox}/development/data/derived"
global donations "${dropbox}/Politics of Housing Segregation/data/cleaned_data/alderman_elections/campaign_donations"
global export "${dropbox}/development/figures"

*Import exposure 
import delim "${data}/ward_qoz_exposure", clear
tempfile exposure 
save `exposure'

*Load in Donations Data
use "/Users/tylerjacobson/Dropbox/Politics of Housing Segregation/data/cleaned_data/alderman_elections/campaign_donations/chicago_campaign_donations.dta", clear

keep filer candidate election_year office_sought original_name contributor specific_business general_industry broad_sector amount date employer

*Cleaning Up Office Sought
gen office = .
replace office = 0 if office_sought == "MAYOR"
replace office_sought = subinstr(office_sought, "CITY COUNCIL DISTRICT", "",.)
destring office_sought, replace force 
replace office = office_sought if missing(office)

gen ward = office if office != 0 

*Getting Year of Donation
gen donation_year = substr(date, 1, 4)
destring donation_year, replace

*Looking for Real Estate Donations
gen real_estate = . 
replace real_estate = 1 if inlist(general_industry, "Construction Services", "General Contractors", "Home Builders", "Real Estate")
replace real_estate = 1 if broad_sector == "Construction"


gen employer_re = 0 
replace employer_re = strpos(employer, "REAL ESTATE") != 0 if employer_re == 0
replace employer_re = strpos(employer, "DEVELOPMENT") != 0 if employer_re == 0
replace real_estate = 1 if employer_re == 1

gen amount_real_estate = amount if real_estate == 1
drop if mi(donation_year) | donation_year == 0 

collapse (rawsum) amount amount_real_estate, by(ward donation_year)


rename ward ward2015 
keep if donation_year >= 2011
xtset ward2015 donation_year
tsfill, full
replace amount = 0 if mi(amount)
replace amount_real_estate = 0 if mi(amount_real_estate)


merge m:1 ward2015 using `exposure'

gen l_amount = log(amount)

binscatter amount frac_qoz if inlist(donation_year, 2015, 2019), by(donation_year) ///
line(connect) 

forvalues year = 2011/2019 {
	gen frac_qoz_`year' = frac_qoz if `year' == donation_year
	replace frac_qoz_`year' = 0 if mi(frac_qoz_`year')
	
	foreach y in amount_real_estate amount {
		reg `y' frac_qoz if donation_year == `year'
		local c_`y'_`year' = _b[frac_qoz]
		local se_`y'_`year' = _se[frac_qoz]
	}
}

drop frac_qoz_2017 
reg amount i.donation_year frac_qoz frac_qoz_*, r


clear 
set obs 5 
gen year = _n + 2014

foreach y in amount_real_estate amount {
	gen coef_`y' = . 
	gen se_`y' = . 
	forvalues year = 2015/2019 {
		replace coef_`y' = `c_`y'_`year'' if `year' == year
		replace se_`y' = `se_`y'_`year'' if `year' == year
	}
	gen u_`y' = coef_`y' + 1.96*se_`y'
	gen l_`y' = coef_`y' - 1.96*se_`y'
	}
	
tw 	(connect coef_amount_real_estate year) ///
	(rcap u_amount_real_estate l_amount_real_estate  year)
	e
tw 	(connect coef_amount year) ///
	(rcap u_amount l_amount  year)
