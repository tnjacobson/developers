*Looking at NYC Trends


*Cleaning Building Permits

global project "${dropbox}/housing fragmentation"
global data "${project}/data/raw/census_bps"
global derived "${project}/data/derived"
global figures "${dropbox}/development/figures/nyc_charter"

set seed 151515


use "${derived}/bps_panel", clear 
gen nyc = state_fips == "36" & inlist(county_fips, "005", "081", "047", "061", "085")

collapse (rawsum) units*, by(nyc year)

foreach var in units_1 units_2 units_5 units_34  {
	gen temp = `var' if year == 1989
	bys nyc: egen temp2 = max(temp)
	gen `var'_1989 = `var'/temp2
	drop temp temp2
}

keep if inrange(year, 1985, 2000)
tw (connect units_5_1989 year if nyc == 0, color(navy%60)) ///
	(connect units_5_1989 year if nyc == 1, color(navy)) 
e	
	
	
	(connect units_2_1989 year) ///
	(connect units_34_1989 year) (connect units_5_1989 year)
