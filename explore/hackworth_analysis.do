*Comparing Housing Construction By Poverty Rate Over Time

global hackworth "${dropbox}/development/hackworth_dissertation"
global output "${dropbox}/development/figures/nyc_charter"

*-------------------------------------------------------------------------------
*Prep Census
*-------------------------------------------------------------------------------
import delim "${census}/tract_various/nhgis0022_ds151_2000_tract.csv", clear


gen pov_rate = gn6001/(gn6001 + gn6002)
keep statea countya tracta pov_rate 
bys statea countya tracta : keep if _n == 1

gen str2 state_str = string(state, "%02.0f")
gen str3 county_str = string(county, "%03.0f")
gen str6 tract_str = string(tract, "%06.0f")

gen geoid = state_str + county_str + tract_str

tempfile census 
save `census'

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

append using `early' 
tab year 

gen geoid = subinstr(CT,".","",.)

merge m:1 geoid using `census', keep(1 3) 

drop if _merge == 1 | mi(pov_rate)

gen pre = year <= 1989

gen unitchange_pre = unitchange if year <= 1989
gen unitchange_post = unitchange if year > 1989

collapse (rawsum) unitchange* count, by(CT pov_rate)

binscatter unitchange_pre unitchange_post pov_rate, line(connect) ///
	ytitle("Housing Units Built") ///
	legend(order(1 "1977-1989" 2 "1990-1997") ring(0) col(1) pos(2) size(medium)) ///
	xtitle("2000 Poverty Rate")
	
graph export "${output}/hackworth_housing_units_pre_post.pdf", replace




gen change = (unitchange_post/unitchange_pre)-1

binscatter change pov_rate
