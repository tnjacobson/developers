*Explore How Well the GIS Join Looks 

global data "${dropbox}/development/data/intermediate"
global output "${dropbox}/development/output/cleaning"
cap mkdir "${output}"

import delim "${data}/test_join", clear varnames(1)

*Cleaning Variables 
gen date_clerk = substr(final_date,1,10)
replace date_clerk = "" if date_clerk == "NA"
gen date_clerk_temp = date(date_clerk, "MDY")
drop date_clerk 
rename date_clerk_temp date_clerk

gen date_map = date(ordinance1, "YMD")
gen match_date = date_map == date_clerk if !mi(date_clerk) & !mi(date_map)
sum match_date

gen has_ordinance = ordinance1 != "NA"

gen match_code = record__ == clerk_docn if record__ != "NA" & clerk_docn != "NA"


format date_clerk %td

gen year = year(date_clerk)

drop if year == 2010
*Check Whether there is an Ordinance
binscatter has_ordinance year, discrete line(connect) ///
	ytitle("Matched with Zoning Map") ///
	xtitle("Year") xlabel(2010(2)2022)
graph export "${output}/clerk_match_map_ordinance.pdf", replace

*Check Whether there is an Ordinance
binscatter match_date year if has_ordinance == 1, discrete line(connect) ///
	ytitle("Ordinance Date Match") ///
	xtitle("Year") xlabel(2010(2)2022)
graph export "${output}/clerk_match_date_map_ordinance.pdf", replace

*Check Whether there is an Ordinance
binscatter match_code year if has_ordinance == 1, discrete line(connect) ///
	ytitle("Ordinance Code Match") ///
	xtitle("Year") xlabel(2010(2)2022)
graph export "${output}/clerk_match_code_map_ordinance.pdf", replace


*Testing if Other Ways of Writing Code
foreach var in record__ clerk_docn {
	gen `var'_clean = subinstr(`var', "SO", "",.)
	replace `var'_clean = subinstr(`var'_clean, "O", "",.)
	replace `var'_clean = subinstr(`var'_clean, "S0", "",.)
}

gen match_code_clean = record___clean == clerk_docn_clean if record__ != "NA" & clerk_docn != "NA"


*Check Whether there is an Ordinance
binscatter match_code_clean year if has_ordinance == 1, discrete line(connect) ///
	ytitle("Ordinance Code Match") ///
	xtitle("Year") xlabel(2010(2)2022)
graph export "${output}/clerk_match_code_clean_map_ordinance.pdf", replace

sum match_code_clean 

br if match_code_clean == 0 


gen map_after = date_map > date_clerk if !mi(date_map)

sum map_after if match_code_clean == 0 
