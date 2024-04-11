*Exploring Fuzzy Merge
if "`c(os)'" == "MacOSX" {
global derived  "${dropbox}/development/data/derived/nyc"
global raw   "${dropbox}/development/data/raw/nyc_housing"
}
else {
	global derived "~/developers/derived/nyc"
	global raw "~/developers/derived/nyc"
}
*-----
*Loading in Firms
use "${raw}/Active_Corporations___Beginning_1800_20240202.dta" if substr(ownersbusinessname, 1,1) == "A", clear

replace ownersbusinessname = strlower(ownersbusinessname)
bys ownersbusinessname: keep if _n == 1

gen id_firm = _n

tempfile firmsa 
save `firmsa'

*Loading in Permits
use "${derived}/dob_permits" if substr(ownersbusinessname, 1,1) == "A", clear

*Only Keeping Private Business
keep if inlist(ownersbusinesstype, "CORPORATION", "INDIVIDUAL", "PARTNERSHIP", ///
	"OTHER")
	
replace ownersbusinessname = strlower(ownersbusinessname)
bys ownersbusinessname: keep if _n == 1

gen id = _n 
	
matchit id ownersbusinessname using `firmsa', ///
	idusing(id_firm) txtusing(ownersbusinessname)  override 
