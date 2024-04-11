*Looking at Census Trends




global data "${dropbox}/development/data"
global graphics "${dropbox}/development/figures/census"
cap mkdir "${graphics}"

*-------------------------------------------------------------------------------
*Load in Data
*-------------------------------------------------------------------------------
import delim "${data}/derived/census_data/census_data_tracts", clear 


*Restrict to Right Years
keep if panel_year == 2010 | panel_year == 2019

keep income_median rent_median geoid pop_total panel_year share_black

reshape wide income_median rent_median pop_total share_black, i(geoid) j(panel_year)


gen ch_pop = (pop_total2019/pop_total2010 - 1)*100
destring income_median2010, replace force

binscatter ch_pop income_median2010 [w=pop_total2010], yline(0, lpattern(dash) lcolor(gray))

xtile income_median2010_q = income_median2010, nq(10)

collapse (mean) ch_pop [w=pop_total2010], by(income_median2010_q)

graph bar ch_pop, over(income_median2010_q)  ///
	ytitle("Percent Change in Population") ///
	b1title("Tract Income Decile") ///
	ylabel(,nogrid)
	
graph export "${graphics}/change_pop_income.pdf", replace
