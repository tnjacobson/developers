*Benchmarking Permits in NYC 


global census  "${dropbox}/development/data/derived/census_permits_survey"
global derived  "${dropbox}/development/data/derived"
global export "${dropbox}/development/figures/nyc"


use "${derived}/nyc/dob_permits_firm_ids", clear

merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3)

sum proposeddwellingunits, d 
gen count = 1 
drop if mi(firm)
drop if mi(council_district)

tempfile data 
save `data'
foreach type in sf mf {
	use `data', clear 
	if "`type'" == "sf" {
		keep if proposeddwellingunits == 1
	}	

	if "`type'" == "mf" {
		keep if proposeddwellingunits >= 10 & !mi(proposeddwellingunits)
	}	


	*keep if proposeddwellingunits >= 50
	bys firm: gen permits_firm = _N
	bys firm: egen units_firm = total(proposeddwellingunits)
	bys firm: gen firm_rank = _n
	bys firm: egen entry = min(issuance_year)
	gen firm_age = issuance_year - entry
	gen firm_share =units_firm/ 533589

	/*Chetrit
	br if firm == "6462309360"

	*Extel 
	br if strpos(owner,"barnett") != 0 
	br if firm == "2127126000"
	sum permits_firm if firm_rank == 1 , d
	sum units_firm if firm_rank == 1 , d 

	br if ownersphone == "7182464762"
	*/


	*Collapse to Council Permits Level
	collapse (rawsum) proposeddwellingunits count  ,by(council_district firm)

	*Get Totals
	bys council_district: egen total_council = total(proposeddwellingunits )
	bys council_district: egen total_council_permits = total(count )
	bys firm: egen total_firm = total(proposeddwellingunits)
	bys firm: egen total_firm_permits = total(count)

	*Get Shares
	gen share_firm = proposeddwellingunits /total_firm
	gen share_firm_permits =count /total_firm_permits
	gen share_council = proposeddwellingunits /total_council
	gen share_council_permits = count /total_council_permits


	*Histogram of Firm Permit Shares
	foreach var in _firm _firm_permits {
		preserve

		*Keep Largest Project
		if "`var'" == "_firm_permits" {
			bys firm (count): keep if _n == _N
			local title "Largest Fraction of Firm's Permits in Single District"
		}
		
		*Keep Largest Project
		if "`var'" == "_firm" {
			bys firm (proposeddwellingunits): keep if _n == _N
			local title "Largest Fraction of Firm's Units in Single District"
		}
		
		*Unrestricted 
		hist share`var', ///
			xtitle("`title'") ///
			xlabel(0(.2)1) ///
			ylabel(none)
		graph export "${export}/hist_`type'_`var'.pdf", replace
			
		*At Least 2 Projects
		hist share`var' if total_firm_permits >= 2, ///
			xtitle("`title'") ///
			xlabel(0(.2)1) ///
			ylabel(none)
		graph export "${export}/hist_`type'_`var'_2.pdf", replace 

			
		hist share`var' if total_firm_permits >= 10, ///
			xtitle("`title'") ///
			xlabel(0(.2)1) ///
			ylabel(none)
		graph export "${export}/hist_`type'_`var'_10.pdf", replace 
			
		restore
	}
}


*Looking At Overall Distribution
use "${derived}/nyc/dob_permits_firm_ids", clear
drop if mi(council_district)
merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3)

sum proposeddwellingunits, d 
gen count = 1 
drop if mi(firm)

keep if proposeddwellingunits >= 10 & !mi(proposeddwellingunits)

collapse (rawsum) proposeddwellingunits count, by(council_district)


sum proposeddwellingunits
gen share_units = proposeddwellingunits / `r(sum)'

sum count
gen share_permits = count / `r(sum)'

hist share_units, ///
			xtitle("Share of Units Built in District") ///
			xlabel(0(.2)1) ///
			ylabel(none)
graph export "${export}/hist_share_units_distrct.pdf", replace 
hist share_permits, ///
			xtitle("Share of Permits Built in District") ///
			xlabel(0(.2)1) ///
			ylabel(none)
graph export "${export}/hist_share_permits_distrct.pdf", replace 
e



preserve
bys firm (proposeddwellingunits): keep if _n == _N
hist share_firm 
hist share_firm if total_firm_permits >= 2
restore

hist share_firm if total_firm_permits >= 5
hist share_firm_projects if total_firm_permits >= 5 

hist share_council


gen districts = 1 

collapse (rawsum) count proposeddwellingunits districts,by(firm)

hist share_firm if count != 1

*Rabsky
br if firm == "2124213535"

*Related
br if firm =="2124215332"

gen hhi_share = (share_council*100)^2

collapse (rawsum) hhi_share proposeddwellingunits ,by(council_district)

sum hhi, d 

*HHI Assuming Every Building is Separate 
use "${derived}/nyc/dob_permits_firm_ids", clear
merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3)
bys council_district: egen total_council = total(proposeddwellingunits )
gen share_council = proposeddwellingunits /total_council
gen hhi_share = (share_council*100)^2
collapse (rawsum) hhi_share proposeddwellingunits ,by(council_district)
sum hhi, d 

*HHI In City Overall
use "${derived}/nyc/dob_permits_firm_ids", clear
merge m:1 job using "${derived}/nyc/dob_jobs",  keepusing(proposeddwellingunits) keep(3)
keep if proposeddwellingunits >= 50

collapse (rawsum) proposeddwellingunits,by(firm)
egen total_city = total(proposeddwellingunits )
gen share_city = proposeddwellingunits /total_city
gen hhi_share = (share_city*100)^2
collapse (rawsum) hhi_share 

