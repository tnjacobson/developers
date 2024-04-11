

*Merging Lobbying Records with Business Names
global data "~/developers/raw/nyc_housing"
global output "~/developers/derived/nyc"

global data "${dropbox}/development/data/raw/nyc_housing"

*Load in Corp Data
use "${data}/Active_Corporations___Beginning_1800_20240202", clear


replace entity = strlower(entity)
bys currententityname: keep if _n == 1

rename currententityname entity
compress


*Splitting By First String
forvalues i = 1/26 {
	preserve
    // Convert the loop index to the corresponding ASCII code for lowercase letters
    local letter = char(`i' + 96)
    
	keep if substr(entity,1,1) == "`letter'"
	tempfile corp_`letter'
	save `corp_`letter''
	restore
}
forvalues i = 0/9 {
	preserve
    // Convert the loop index to the corresponding ASCII code for lowercase letters
    
	keep if substr(entity,1,1) == "`i'"
	tempfile corp_`i'
	save `corp_`i''
	restore
}

*Loading in Lobbying Data
import delim "${data}/lobbying/City_Clerk_eLobbyist_Data_20240201.csv", clear
keep if client_industry == "Real Estate, Construction, Engineering & Developer"
rename client_name entity 

replace entity = strlower(entity)
collapse (rawsum) compensation_total, by(entity)


*Splitting By First String
forvalues i = 1/26 {
	preserve
    // Convert the loop index to the corresponding ASCII code for lowercase letters
    local letter = char(`i' + 96)
    
	keep if substr(entity,1,1) == "`letter'"
	
	merge 1:1 entity using `corp_`letter'', keep(1 3)
	
	tempfile merge_`letter'
	save `merge_`letter''
	restore
}
forvalues i = 0/9 {
	preserve
    // Convert the loop index to the corresponding ASCII code for lowercase letters
    
	keep if substr(entity,1,1) == "`i'"
	
	merge 1:1 entity using `corp_`i', keep(1 3)

	tempfile merge_`i'
	save `merge_`i''
	restore
}

clear 
forvalues i = 1/26 {
	append using `merge_`letter''
}
forvalues i = 0/9 {
	append using `merge_`i''
}

save "${output}/merge_lobbying_corp", replace
