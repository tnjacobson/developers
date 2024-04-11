*Build Annual Building Permits Data


global derived "${dropbox}/development/data/derived/census_permits_survey"
cap mkdir ${derived}


*-------------------------------------------------------------------------------
*Load in Data
*-------------------------------------------------------------------------------
forvalues year = 2000/2020 {
	import delim "https://www2.census.gov/econ/bps/County/co`year'a.txt", clear

	rename v1 year
	rename v2 state 
	rename v3 county 
	rename v6 county_name
	rename v8 units_1
	rename v11 units_2 
	rename v14 units_34 
	rename v17 units_5

	keep year state county* units* 
	drop if inlist(year, "Survey", "Date", " ")
	destring year state county units*, replace

	egen units = rowtotal(units*)
	tempfile a`year'
	save `a`year''
}

clear 
forvalues year = 2000/2020 {
	append using `a`year''
}
bys year state county: drop if _N > 1
save "${derived}/bps_survey", replace

tw connect units_1 year if state == 17 & county == 31
