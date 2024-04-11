*Comparing Housing Construction By Poverty Rate Over Time

global hackworth "${dropbox}/development/hackworth_dissertation"
global output "${dropbox}/development/figures/nyc_charter"

*-------------------------------------------------------------------------------
*Load Hackworth
*-------------------------------------------------------------------------------

*Load in Housing Construction Data
import excel "${hackworth}/HousingUnitChanges/NewConstruct.xls", clear ///
	sheet(7789) firstrow
	
	
forvalues t = 77/89 {
	rename Y`t'_1UnitChange  unitchange19`t'
	rename Y`t'_1Count  count19`t'

}

keep CT Borough unitchange19* count19*

reshape long unitchange count, i(CT Borough) j(year)

collapse (rawsum) unitchange count, by(year)

tw (connect unitchange year)

tempfile early 
save `early'


*Load in Housing Construction Data
import excel "${hackworth}/HousingUnitChanges/NewConstruct.xls", clear ///
	sheet(9097) firstrow
	
	
forvalues t = 90/97 {
	rename Y`t'1_1UnitChange  unitchange119`t'
	rename Y`t'1_2UnitChange  unitchange219`t'
	gen unitchange19`t' = unitchange119`t' + unitchange219`t'
	
	
	rename Y`t'1_1Count  count119`t'
	rename Y`t'1_2Count  count219`t'
	gen count19`t' = count119`t' + count219`t'
}


keep CT Borough unitchange19* count19*

reshape long unitchange count, i(CT Borough) j(year)

collapse (rawsum) unitchange count, by(year)

append using `early' 
sort year


tw (connect count year)

tempfile hackworth
save `hackworth'


*-------------------------------------------------------------------------------
*Load BPS
*-------------------------------------------------------------------------------
*Looking at NYC Trends


*Cleaning Building Permits

global project "${dropbox}/housing fragmentation"
global derived "${project}/data/derived"

use "${derived}/bps_panel", clear 
egen total_units = rowtotal(units*)
egen total_bldgs = rowtotal(bldgs*)
gen nyc = state_fips == "36" & inlist(county_fips, "005", "081", "047", "061", "085")
keep if nyc == 1

collapse (rawsum) total_units total_bldgs, by(year)

merge 1:1 year using `hackworth'

sort year 
tw 	(connect total_bldgs year if inrange(year, 1977, 1997)) ///
	(connect count year if inrange(year, 1977, 1997))
tw 	(connect total_units year if inrange(year, 1977, 1997)) ///
	(connect unitchange year if inrange(year, 1977, 1997))
		
e

