


*Simulating Border Design
local locations = 1000
clear 
set obs `locations'
gen n = _n 
gen j = _n/`locations'
gen measure = 1/`locations'

gen pi_equal = .5 
gen pi_neighborhood = .8 -.6*j

gen pi_district = .8
replace pi_district = .2 if j >= .5

gen pi_both = .8 - .4*j 
replace pi_both = pi_both - .2 if j >= .5 
sum pi*

tw 	(line pi_equal j) ///
	(line pi_neighborhood j) ///
	(line pi_district j) ///
	(line pi_both j)
	
	
tw 	(line pi_district j), ///
	ytitle("Probability Firm 1 Builds")

	
		
tw 	(line pi_neighborhood j), ///
	ytitle("Probability Firm 1 Builds")



foreach type in equal district both neighborhood {
		gen ms_`type' = . 
		gen hhi_`type'_1 = . 
		gen hhi_`type'_2 = . 

forvalues i = 1/999 {
		sum pi_`type' if n <= `i'
		replace ms_`type' = `r(mean)' if n == `i'
		replace hhi_`type'_1 = (`r(mean)'*100)^2 + ((1-`r(mean)')*100)^2 if n == `i'
		
		sum pi_`type' if n > `i'
		replace hhi_`type'_2 = (`r(mean)'*100)^2 + ((1-`r(mean)')*100)^2 if n == `i'

	}
	
	gen avg_hhi_`type' =  hhi_`type'_1*j + hhi_`type'_2*(1-j)
	gen avg_hhi_`type'_unw =  hhi_`type'_1 + hhi_`type'_2


}




	tw (line avg_hhi_district j), ///
		xtitle("Hypothetical Border Drawn At") ///
		ytitle("Average HHI Across Hypothetical Districts")

e
	tw (line avg_hhi_neighborhood j), ///
		xtitle("Hypothetical Border Drawn At") ///
		ytitle("Average HHI Across Hypothetical Districts")
	
	
	
tw 	(line avg_hhi_equal j) ///
	(line avg_hhi_neighborhood j) ///
	(line avg_hhi_district j) ///
	(line avg_hhi_both j)
	
	sum avg_hhi_both if j == .5
	tw (hist avg_hhi_both), xline(`r(mean)')
	
	sum avg_hhi_neighborhood if j == .5
	tw (hist avg_hhi_neighborhood), xline(`r(mean)')
	
	sum avg_hhi_neighborhood if n == 100
	tw (hist avg_hhi_neighborhood), xline(`r(mean)')
	
	
	
	sum avg_hhi_district if j == .5
	tw (hist avg_hhi_district), xline(`r(mean)')

	
	sum avg_hhi_district_unw if j == .5
	tw (hist avg_hhi_district_unw), xline(`r(mean)')
