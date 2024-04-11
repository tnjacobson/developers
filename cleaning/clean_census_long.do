*Clean Census Data
global census "${dropbox}/development/data/raw/nhgis"
global hackworth "${dropbox}/development/hackworth_dissertation"
global output "${dropbox}/development/figures/nyc_charter"
global data "${dropbox}/development/data/raw"

*-------------------------------------------------------------------------------
*1980
*-------------------------------------------------------------------------------


import delim "${census}/tract_various/nhgis0022_ds104_1980_tract.csv", clear

rename c7l001 pop
rename c8y001 housing_units
rename c9d001 white 
rename c9d002 black
gen share_black = black/pop

keep statea countya tracta pop housing_units share_black
bys statea countya tracta : keep if _n == 1
tempfile pop
save `pop'

import delim "${census}/tract_various/nhgis0022_ds107_1980_tract.csv", clear

gen pov_rate = di8002/(di8001+di8002)
 
keep statea countya tracta pov_rate 
bys statea countya tracta : keep if _n == 1


merge 1:1 statea countya tracta using `pop', nogen assert(3)

rename (pop housing_units pov_rate share_black)=_1980

tempfile c1980 
save `c1980'

*-------------------------------------------------------------------------------
*1990
*-------------------------------------------------------------------------------


import delim "${census}/tract_various/nhgis0022_ds120_1990_tract.csv", clear

rename et1001 pop
rename esa001 housing_units
rename euy001 white 
rename euy002 black
gen share_black = black/pop

keep statea countya tracta pop housing_units share_black
bys statea countya tracta : keep if _n == 1
tempfile pop
save `pop'

import delim "${census}/tract_various/nhgis0022_ds123_1990_tract.csv", clear

gen inc_above = 0
gen inc_below = 0 

forvalues i = 1/9 {
	replace inc_above = inc_above + e0700`i'
}
forvalues i = 10/12 {
	replace inc_above = inc_above + e070`i'
}
forvalues i = 13/24 {
	replace inc_below = inc_below + e070`i'
}
gen pov_rate = inc_below/(inc_above + inc_below)
keep statea countya tracta pov_rate 
bys statea countya tracta : keep if _n == 1

merge 1:1 statea countya tracta using `pop', nogen assert(3)

rename (pop housing_units pov_rate share_black)=_1990

tempfile c1990 
save `c1990'

*-------------------------------------------------------------------------------
*2000
*-------------------------------------------------------------------------------
import delim "${census}/tract_various/nhgis0022_ds146_2000_tract.csv", clear

rename fl5001 pop
rename fki001 housing_units
rename fmr002 black
gen share_black = black/pop

keep statea countya tracta pop housing_units share_black
bys statea countya tracta : keep if _n == 1
tempfile pop
save `pop'

import delim "${census}/tract_various/nhgis0022_ds151_2000_tract.csv", clear


gen pov_rate = gn6001/(gn6001 + gn6002)
keep statea countya tracta pov_rate 
bys statea countya tracta : keep if _n == 1

merge 1:1 statea countya tracta using `pop', nogen assert(3)

rename (pop housing_units pov_rate share_black)=_2000

tempfile c2000
save `c2000'

*-------------------------------------------------------------------------------
*Crosswalking
*-------------------------------------------------------------------------------
*foreach year in 1980 1990 2000 {
	
	use `c1980', clear
	keep if statea == 36 & inlist(countya, 5,47,61,81,85)
	merge 1:1 statea countya tracta using `c1990', keep(3) nogen
	replace tracta = tracta*100
	merge 1:1 statea countya tracta using `c2000', keep(3) nogen
	
	gen ch_housing_8090 = housing_units_1990-housing_units_1980
	gen ch_housing_9000 = housing_units_2000-housing_units_1990

	binscatter ch_housing_8090 ch_housing_9000 pov_rate_1980 [w=pop_1980], ///
	ytitle("Change in Housing Units") ///
	xtitle("Poverty Rate in 1980") ///
	legend(order(1 "1980-1990" 2 "1990-2000") ring(0) pos(2) col(1) size(medium))
	
	graph export "${output}/census_housing_units_pre_post.pdf", replace
e
	