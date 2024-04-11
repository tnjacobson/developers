**Explore Housing Data 

global data "${dropbox}/development/data/derived"
global export "${dropbox}/development/figures"


import delim "${data}/housing/housing_construction", clear
destring year_built units, replace force
 
keep if inrange(year_built, 2010, 2020)

gen pd = substr(zone_class2023,1,2) == "PD"
gen ch = zone_class2023 != zone_class2012
drop if mi(units)
gen bin = . 
replace bin = 1 if units == 1 
replace bin = 2 if units <= 10 & mi(bin)
replace bin = 3 if units <= 50 & mi(bin)
replace bin = 4 if units <= 100 & mi(bin)
replace bin = 5 if units > 100 & mi(bin)



gen ch_pd = ch == 1 | pd == 1 
 
 
graph bar ch_pd , over(bin, relabel(1 "Single Unit" 2 "2-10 Units" 3 "11-50 Units" 4 "51-100 Units" 5 ">100 Units") ) ytitle("Fraction Requiring Zoning Change or PD")
graph export "${export}/bar_units_zoning.pdf", replace 
e 

binscatter ch_pd year_built, discrete line(connect)

collapse (rawsum) units,  by(year_built)
tw connect units year_built

*Looking at zoning changes
import delim "${data}/rezoning/zoning_changes", clear

gen year = substr(final_date_clerk, 7,4)
destring year, replace

gen count =1 
collapse (rawsum) count, by(year)
tw connect count year if inrange(year, 2011, 2019)
