*Build NYC Housing Analysis Data
if "`c(os)'" == "MacOSX" {
global derived  "${dropbox}/development/data/derived/nyc"
}
else {
	global derived "~/developers/derived/nyc"
}
*-----


use "${derived}/dob_permits", clear

*Only Keeping Private Business
keep if inlist(ownersbusinesstype, "CORPORATION", "INDIVIDUAL", "PARTNERSHIP", ///
	"OTHER")

*-------------------------------------------------------------------------------
*Cleaning Information
*-------------------------------------------------------------------------------
gen owner = ownersfirstname +  " " + ownerslastname
replace owner = strlower(owner)
replace ownersbusinessname = strlower(ownersbusinessname)

*Cleaning Strings
foreach var in owner ownersbusinessname ownersphone {

	replace `var' = strtrim(`var')
	replace `var' = subinstr(`var', "}","",.)
	replace `var' = subinstr(`var', "{","",.)
	replace `var' = subinstr(`var', "'","",.)
	replace `var' = subinstr(`var', ",","",.)
	replace `var' = subinstr(`var', ".","",.)
	replace `var' = subinstr(`var', "/","",.)
	replace `var' = subinstr(`var', "\","",.)
	replace `var' = subinstr(`var', "-","",.)
	replace `var' = subinstr(`var', "`","",.)

	replace `var' = "" if `var' == "na"
	replace `var' = "" if `var' == "none"
	
	
	bys `var': gen `var'_N = _N
	bys `var': gen `var'_n = _n
	

}



*Sorting out uninformative phone numbers
gen length = strlen(ownersphone)
replace ownersphone = "" if length != 10
destring ownersphone, gen(numeric) force
replace ownersphone = "" if numeric == .
	

replace ownersphone = "" if inlist(ownersphone,"9999999999", "0000000000", ///
	"1111111111", ///
	"2222222222", ///
	"3333333333", ///
	"2120000000", "7180000000", "7189999999", ///
	"7181111111")
	
replace ownersphone = "" if substr(ownersphone,7,4) == "0000"


*Sorting out uninformative business names
*Dropping HPD and Other City Agencies
keep if inlist(strpos(ownersbusinessname, "h p d") ,0)
keep if inlist(strpos(ownersbusinessname, "hpd") ,0)
keep if inlist(strpos(ownersbusinessname, "nyc dep") ,0)
keep if inlist(strpos(ownersbusinessname, "nyc dep") ,0)
keep if inlist(strpos(ownersbusinessname, "housing preservation") ,0)

keep if ownersbusinessname != "nyc housing preservation & deve"
keep if ownersbusinessname != "nyc housing preservation & deve"
keep if ownersbusinessname !=  "city of new york"
keep if ownersbusinessname != "housing preservation & developme"

*Getting Rid of Uninformative Acronyms
replace ownersbusinessname = "" if ownersbusinessname == "llc"

*Removing Uninformative Information
replace ownersbusinessname = "" if ownersbusinessname == "president"
replace ownersbusinessname = "" if ownersbusinessname == "homeowner"
replace ownersbusinessname = "" if ownersbusinessname == "individual"
replace ownersbusinessname = "" if ownersbusinessname == "owner"
replace ownersbusinessname = "" if ownersbusinessname == "same"
replace ownersbusinessname = "" if ownersbusinessname == "self"
replace ownersbusinessname = "" if ownersbusinessname == "1"


*Removing Uninformative Terms at end of strings 
foreach term in "llc" "inc" "co" "corp" "lp" "group" "ltd" {
	replace ownersbusinessname = regexr(ownersbusinessname, " `term'$", "")

}

*Removing leading strings
replace ownersbusinessname = strtrim(ownersbusinessname)


*Sorting Out Owners

*Timothy Joseph is HPD (By Inspection)
drop if owner == "timothy joseph"
drop if owner == "tim joseph"

drop *_N *_n 


*-------------------------------------------------------------------------------
*Running Algorithm
*-------------------------------------------------------------------------------
gen classified = 0
gen firm = ""
local i = 1
levelsof ownersphone
foreach p in `r(levels)' {

	di "iteration: `i'"
	*First Check if Phone Number is Already Classified
	count if ownersphone == "`p'" & classified == 1 
	if `r(N)' != 0 {	
		}
	else {
		*Initial Count
		local count_old = 0 
		
		*Adding Firms
		replace firm = "`p'" if ownersphone == "`p'"
		replace classified = 1 if ownersphone == "`p'"
		count if firm == "`p'" 
		local count_new = `r(N)'
		
		while `count_old' != `count_new' {
			local count_old = `count_new'
			
			*Looking for owner names
			foreach var in owner ownersbusinessname ownersphone {
			qui levelsof `var' if firm ==  "`p'" 
				foreach o in `r(levels)' {
					replace firm = "`p'" if `var' == "`o'"
					replace classified = 1 if `var' == "`o'"
				}
			}
			
			count if firm ==  "`p'" 
			local count_new = `r(N)'
		}

	}
}

save "${derived}/dob_permits_firm_ids", replace
e

*Get Proposed Dwelling Units from Jobs Data
merge 1:1 job using "${derived}/nyc/dob_jobs", keep(3) keepusing(proposeddwellingunits) nogen



bys firm: gen N = _N
bys firm: egen firm_units = total(proposeddwellingunits)
bys council_district: egen council_total = total(proposeddwellingunits)
e

br if ownersfirstname == "GERALD" & ownerslastname == "WOLKOFF"
br if ownersphone == "5162426300" | ownersphone == "6312426300"

br if ownersfirstname == "DAVID" & ownerslastname == "WOLKOFF"

br if ownersfirstname == "GREG" & ownerslastname == "WOLKOFF"
br if ownersphone == "7186681200"
br if ownerslastname == "WOLKOFF"


br if  ownerslastname == "BLAU"



*Identifying All Related Projects
replace owner = strlower(owner)
replace ownersbusinessname = strlower(ownersbusinessname)

foreach var in owner ownersbusinessname ownersphone {
	replace `var' = "" if `var' == "na"
	replace `var' = "" if `var' == "n/a"
}



*-------------------------------------------------------------------------------
*Finding Related Group Properties
*-------------------------------------------------------------------------------

*Start with a phone number
local count_old = 0
gen related = 0
replace related = 1 if ownersphone == "2124215333"
br if related == 1
count if related == 1  
local count_new = `r(N)'

*Look for all owner names that match
while `count_old' != `count_new' {
	count if related == 1  
	local count_old = `r(N)'
	
	
	*Looking for owner names
	foreach var in owner ownersbusinessname ownersphone {
	qui levelsof `var' if related == 1 
		foreach o in `r(levels)' {
			replace related = 1 if `var' == "`o'"
		}
	}
	
	count if related == 1  
	local count_new = `r(N)'
	
}


*-------------------------------------------------------------------------------
*Finding G and M
*-------------------------------------------------------------------------------

*Start with a phone number
local count_old = 0
gen gm = 0
replace gm = 1 if ownersphone == "6312426300"
replace gm = 1 if owner == "gerald wolkoff"

br if gm == 1
count if gm == 1  
local count_new = `r(N)'

*Look for all owner names that match
while `count_old' != `count_new' {
	count if gm == 1  
	local count_old = `r(N)'
	
	
	*Looking for owner names
	foreach var in owner ownersbusinessname ownersphone {
	qui levelsof `var' if gm == 1 
		foreach o in `r(levels)' {
			replace gm = 1 if `var' == "`o'"
		}
	}
	
	count if gm == 1  
	local count_new = `r(N)'
	
}

*-------------------------------------------------------------------------------
*Finding Rabsky
*-------------------------------------------------------------------------------

*Start with a phone number
local count_old = 0
gen rabsky = 0
replace rabsky = 1 if ownersphone == "7182464762"

br if rabsky == 1
count if rabsky == 1  
local count_new = `r(N)'

*Look for all owner names that match
while `count_old' != `count_new' {
	count if rabsky == 1  
	local count_old = `r(N)'
	
	
	*Looking for owner names
	foreach var in owner ownersbusinessname ownersphone {
	qui levelsof `var' if rabsky == 1 
		foreach o in `r(levels)' {
			replace rabsky = 1 if `var' == "`o'"
		}
	}
	
	count if rabsky == 1  
	local count_new = `r(N)'
}


