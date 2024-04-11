*Looking at NYC Trends


*Cleaning Building Permits

global project "${dropbox}/housing fragmentation"
global data "${project}/data/raw/census_bps"
global derived "${project}/data/derived"
global figures "${dropbox}/development/figures/nyc_charter"

set seed 151515


use "${derived}/bps_panel", clear 
egen total_units = rowtotal(units*)
gen nyc = state_fips == "36" & inlist(county_fips, "005", "081", "047", "061", "085")

tw (connect total_units year if nyc == 1 & county_fips == "061" & inrange(year, 1980,2000))

collapse (rawsum) total_units units* bldgs* ,by(year nyc)
sort year
tw (connect total_units year if nyc == 1 & inrange(year, 1980,2000))
tw (connect total_units year if nyc == 0 & inrange(year, 1980,2000))

foreach var in total_units units_1 units_5 units_34 bldgs_1 bldgs_5 {
	gen temp = `var' if year == 1989
	bys nyc: egen temp2 = max(temp)
	gen `var'_1989 = `var'/temp2
	drop temp temp2
}

gen frac_multi = (total_units-units_1)/total_units

sort year
tw 	(connect frac_multi year if inrange(year,1980,2000) & nyc == 1  ),  xline(1989.5, lpattern(dash) lcolor(grey%60)) 

tw 	(connect total_units_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect total_units_1989 year if inrange(year,1980,2000) & nyc == 1  ),  xline(1989.5, lpattern(dash) lcolor(grey%60)) ///
		ytitle("Permitted Units Relative to 1989") ///
		xtitle("") ///
		legend(order(1 "US Excluding NYC" 2 "NYC") ///
		ring(0) col(1) pos(7) size(medium))
graph export "${figures}/bps_nyc.pdf", replace	
	
		
	tw 	(connect units_34_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect units_34_1989 year if inrange(year,1980,2000) & nyc == 1  ),  xline(1989.5, lpattern(dash) lcolor(grey%60)) 
		e
	tw 	(connect units_5_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect units_5_1989 year if inrange(year,1980,2000) & nyc == 1  ),  xline(1989.5, lpattern(dash) lcolor(grey%60)) 
		
	tw 	(connect bldgs_1_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect bldgs_1_1989 year if inrange(year,1980,2000) & nyc == 1  ),  xline(1989.5, lpattern(dash) lcolor(grey%60)) 
e		
	tw 	(connect units_1_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect units_1_1989 year if inrange(year,1980,2000) & nyc == 1  ) 
		
	tw 	(connect units_5_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect units_5_1989 year if inrange(year,1980,2000) & nyc == 1  ) 
		
		
	tw 	(connect bldgs_5_1989 year if inrange(year,1980,2000) & nyc == 0  ) ///
		(connect bldgs_5_1989 year if inrange(year,1980,2000) & nyc == 1  ) 
		
gen frac_5 = units_5/total_units 

tw (connect frac_5 year if inrange(year,1980,2000) & nyc == 0 )
		
e
e
egen total_units = rowtotal(units*)

gen big_share = units_5/total_units

tw (connect big_share year) if inrange(year, 1980,2000) & county_fips == "047", xline(1989.5, lpattern(dash) lcolor(grey%60))

tw (connect big_share year) if inrange(year, 1980,2000) & county_fips == "081", xline(1989.5, lpattern(dash) lcolor(grey%60))

tw (connect total_units year) if inrange(year, 1980,2000) & county_fips == "081", xline(1989.5, lpattern(dash) lcolor(grey%60))

tw (connect total_units year) if inrange(year, 1980,2000) & county_fips == "047", xline(1989.5, lpattern(dash) lcolor(grey%60))

tw (connect total_units year) if inrange(year, 1980,2000) & county_fips == "005", xline(1989.5, lpattern(dash) lcolor(grey%60))


binscatter big_share year if inrange(year, 1980,2000) & county_fips != "061", discrete line(connect) by(county_fips)

*tw (connect big_share year if county_fips == ")

*drop if county_fips == "061"

collapse (rawsum) total_units units*, by(year)


gen sf_share = units_1/total_units 
foreach var in units_1 units_5 units_34 {
	gen temp = `var' if year == 1989 
	egen `var'_1989 = max(temp)
	drop temp 
	gen n_`var' = `var'/`var'_1989
}
tw 	(connect units_1 year if inrange(year, 1980,2020)) ///
	(connect units_34 year if inrange(year, 1980,2020)) ///
	(connect units_5 year if inrange(year, 1980,2020)), xline(1989.5, lpattern(dash) lcolor(grey%60))
	
tw (connect total_units year)
	
e
tw (connect sf_share year) if inrange(year, 1980,2000), xline(1989.5, lpattern(dash) lcolor(grey%60))
tw (connect total_units year) if inrange(year, 1980,2000), xline(1989.5, lpattern(dash) lcolor(grey%60))
tw (connect units_5 year)
tw (connect units_1 year) if inrange(year, 1980,2000), xline(1989.5, lpattern(dash) lcolor(grey%60))
tw (connect units_5 year) if inrange(year, 1980,2000), xline(1989.5, lpattern(dash) lcolor(grey%60))


gen big_share = units_5/total_units
tw (connect big_share year) if inrange(year, 1980,2000), xline(1989.5, lpattern(dash) lcolor(grey%60))
