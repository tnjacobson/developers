
global derived "${dropbox}/development/data/derived"
global data "${dropbox}/development/data/raw"
global export "${dropbox}/development/figures/nyc_charter"



*-------------------------------------------------------------------------------
*Explore Current Housing Stock
*-------------------------------------------------------------------------------

use "${data}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear

*Units Built By Decade
gen decade = floor(YearBuilt/10)*10
collapse (rawsum) UnitsRes, by(decade)

replace UnitsRes = UnitsRes/1000
tw (connect UnitsRes decade if inrange(decade,1900,2010)), ///
xlabel(1900(20)2000) ytitle("Units Built Per Decade (1000s)") xtitle("")
graph export "${export}/pluto_units_decade.pdf", replace

*Units Built By Year
use "${data}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear
collapse (rawsum) UnitsRes, by(YearBuilt)

tw (connect UnitsRes YearBuilt if inrange(YearBuilt,1980,2019)), ///
xlabel(1980(5)2020) ytitle("Units Built Per Year") xtitle("") ///
xline(1989.5, lpattern(dash) lcolor(grey%60))
graph export "${export}/pluto_units_year.pdf", replace


*-------------------------------------------------------------------------------
*Define Income Bins Using 2010 Census
*-------------------------------------------------------------------------------
import delim "${data}/nhgis/acs_2010_2014_income/nhgis0023_ds206_20145_tract.csv", clear
keep statea countya tracta abdpe001
rename abdpe001 income
rename (statea countya tracta) (state county tract)
keep if state == 36 & inlist(county, 5,47,61,81, 85)

sum income, d 
gen q =2 
replace q = 1 if income <= `r(p25)'
replace q = 3 if income > `r(p75)'

tempfile census
save `census'




use "${data}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear
gen len = strlen(Tract2010)
replace Tract2010 = Tract2010+"00" if len == 4
destring Tract2010, replace 
rename Tract2010 tract

gen county = . 
replace county = 5 if Borough == "BX"
replace county = 47 if Borough == "BK"
replace county = 61 if Borough == "MN"
replace county = 81 if Borough == "QN"
replace county = 85 if Borough == "SI"

rename UnitsRes units
rename YearBuilt year
keep if inrange(year, 1960, 2020)
collapse (rawsum) units, by(county tract year)
egen group = group(county tract)
drop if mi(group)


*Cleaning Up Time Series
xtset group year
tsfill, full
replace units = 0 if mi(units)
bys group: egen temp = max(county)
replace county = temp if mi(county)
drop temp
bys group: egen temp = max(tract)
replace tract = temp if mi(tract)
drop temp 

merge m:1 county tract using `census', keep(3) nogen


*-------------------------------------------------------------------------------
*Units by Income Tract
*-------------------------------------------------------------------------------
preserve
keep if inrange(year, 1980,2000)
gen post = year > 1990 

collapse (rawsum) units (max) income, by(tract post)

binscatter units income, by(post) line(connect) ///
legend(order(1 "1980s" 2 "1990s") ring(0) pos(11) col(1) size(medium)) ///
ytitle("Units Built") xtitle("2010 Tract Income")
graph export "${export}/binscatter_income.pdf" , replace 



restore 


*-------------------------------------------------------------------------------
*Time Series
*-------------------------------------------------------------------------------
preserve 
collapse (rawsum) units, by(q year)

tw 	(connect units year if q == 1 &inrange(year, 1980,2000)) ///
	(connect units year if q == 2 &inrange(year, 1980,2000)) ///
	(connect units year if q == 3 &inrange(year, 1980,2000)), ///
	ytitle("Units Built") ///
	xtitle("Year") ///
	legend(order(1 "Q1" 2 "Q2-3" 3 "Q4") ring(0) pos(11) size(medium) col(1)) ///
xline(1989.5, lpattern(dash) lcolor(grey%60))
graph export "${export}/pluto_units_income.pdf" , replace 
	
restore 	

*-------------------------------------------------------------------------------
*Regression
*-------------------------------------------------------------------------------

replace income = income/1000

*Running Regression 
forvalues y = 1960/2020 {
	reg units income i.county if year == `y', r
	local coef`y' = _b[income] 
	local se`y' = _se[income] 
}

clear 
set obs 61 
gen year = 1959 +_n 
gen coef = . 
gen se = . 

forvalues y = 1960/2020 {
	replace coef = `coef`y'' if year == `y'
	replace se = `se`y'' if year == `y'
}

gen u_ci = coef + 1.96*se
gen l_ci = coef - 1.96*se
keep if year >= 1975
tw 	(connect coef year, color(navy)) ///
	(line u_ci year, color(navy%60) lpattern(dash) ) ///
	(line l_ci year, color(navy%60) lpattern(dash)), ///
	xline(1989.5, lpattern(dash) lcolor(grey%60))

*-------------------------------------------------------------------------------
*Explore Current Housing Stock
*-------------------------------------------------------------------------------

use "${data}/nyc_housing/nyc_zap/nyc_mappluto_23v3_1_shp/MapPLUTO.dta", clear
rename UnitsRes units
rename YearBuilt year
drop if mi(units)
gen size = .
replace size = 1 if units == 1 
replace size = 2 if inrange(units,2,5) 
replace size = 3 if inrange(units,6,20) 
replace size = 4 if inrange(units,21,100) 
replace size = 5 if units > 100

gen count = 1 

collapse (rawsum) units count, by(size year)
sort year 
keep if inrange(year, 1980,2000)
tw (connect units year if size == 5 )

gen temp = units if year == 1989 
bys size: egen base = max(temp)
gen rel_units = units/base 
sort year
tw (connect rel_units year if size == 5) ///
	(connect rel_units year if size == 3) ///
	(connect rel_units year if size == 1), ///
	legend(order(1 "Units > 100" 2 "Units 6-20" 3 "Single Family") ///
		ring(0) pos(2) col(1) size(medium)) ///
		ytitle("Units Built Relative to 1989") ///
		xtitle("Year")
graph export "${export}/pluto_units_size.pdf", replace

