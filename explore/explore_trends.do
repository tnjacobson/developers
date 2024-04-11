*Making Some Graphs using the Agendas Data


global data "${dropbox}/development/data/intermediate"
global graphics "${dropbox}/development/figures/rezoning"


*-------------------------------------------------------------------------------
*Load in Data
*-------------------------------------------------------------------------------
import delim "${data}/agendas_clean", clear varnames(1)

gen count = 1
collapse (rawsum) count, by()

gen s_date = date(date, "YMD")
gen year = year(s_date)
gen month = month(s_date)

destring floor_area_ratio_*, replace force

foreach var in after before {
	gen temp = pd_`var'_to == "TRUE"
	drop pd_`var'_to 
	rename temp pd_`var'_to
	
	*Tracking Single Res
	gen single_res_`var' = substr(codes_`var'_to_1,1,2) == "RS"
}

gen upzone = floor_area_ratio_after > floor_area_ratio_before if !mi(floor_area_ratio_before) & !mi(floor_area_ratio_after)
gen downzone = floor_area_ratio_after < floor_area_ratio_before if !mi(floor_area_ratio_before) & !mi(floor_area_ratio_after)
gen new_pd = pd_after_to == 1 & pd_before_to == 0

gen from_single_res = single_res_before == 1 & single_res_after == 0
gen to_single_res = single_res_before == 0 & single_res_after == 1


*Graph the Distribution of Changes to Floor Area Ratio
gen ch_FAR = floor_area_ratio_after-floor_area_ratio_before
hist ch_FAR if codes_before_to_1 != codes_after_to_1, ///
	ytitle("Density") xtitle("Change in Floor Area Ratio") 
graph export "${graphics}/change_FAR.pdf", replace

collapse (rawsum) upzone downzone new_pd from_single_res to_single_res, by(year)
drop if year == 2023

tw 	(connect upzone year) ///
	(connect downzone year), ///
	legend(order(1 "Upzoning" 2 "Downzoning" ) col(1) ring(0) pos(11) size(large)) ///
	ytitle("Applications") xtitle("Year") ///
	xlabel(2012(2)2022)
graph export "${graphics}/upzoning_downzoning_ts.pdf", replace

	
tw 	(connect from_single_res year) ///
	(connect to_single_res year), ///
	legend(order(1 "From Single Family" 2 "To Single Family" ) col(1) ring(0) pos(11) size(large)) ///
	ytitle("Applications") xtitle("Year") ///
	xlabel(2012(2)2022) 
graph export "${graphics}/single_fam_ts.pdf", replace
