*Build NYC Housing Analysis Data

global raw  "${dropbox}/development/data/raw"

global derived  "${dropbox}/development/data/derived"

*-------------------------------------------------------------------------------
*Prep Corporations Data
*-------------------------------------------------------------------------------

use currententityname   ///
	dosprocessaddress1 dosprocessaddress2 ///
	dosprocesscity dosprocessstate dosprocesszip ///
	using ///
"${raw}/nyc_housing/Active_Corporations___Beginning_1800_20240202.dta", clear

rename currententityname entity

gen len=length(entity)
summ len

recast str208 entity, force

replace entity = strtrim(entity)
replace entity = subinstr(entity, ",","",.)
replace entity = subinstr(entity, ".","",.)
replace entity = subinstr(entity, " & ","&",.)
replace entity = strlower(entity)
replace entity = subinstr(entity, "llc","",.)
replace entity = subinstr(entity, "l.l.c.","",.)
replace entity = subinstr(entity, "l.l.c.","",.)
replace entity = subinstr(entity, "l.l.c.","",.)



bys entity: keep if _n == 1


keep entity dos* 

tempfile corp 
save `corp'

*-------------------------------------------------------------------------------
*Prep Zoning Changes
*-------------------------------------------------------------------------------


*-------------------------------------------------------------------------------
*Permits Data
*-------------------------------------------------------------------------------


*Start with Permits Data
use "${derived}/nyc/dob_permits", clear

*Get Proposed Dwelling Units from Jobs Data
merge m:1 job using "${derived}/nyc/dob_jobs", keep(3) keepusing(proposeddwellingunits) nogen


rename ownersbusinessname entity 

replace entity = strtrim(entity)
replace entity = subinstr(entity, ",","",.)
replace entity = subinstr(entity, ".","",.)
replace entity = strlower(entity)
replace entity = subinstr(entity, " & ","&",.)
replace entity = subinstr(entity, "llc","",.)
replace entity = subinstr(entity, "l.l.c.","",.)

merge m:1 entity using `corp', keep(1 3) 

replace entity = "" if entity == "n/a"


gen merge = _merge == 3 
sum merge 

gsort -proposeddwellingunits
br if merge == 1 & !mi(entity)


