***Note that the variable positions used in the ACS tables changed with the 2015 ACS, so I could not automate the loading process over years before and after 2015


clear all
set more off


**************************************************
**************Defining fixed parameters***********
**************************************************
	scalar inflate = 1.00		//inflation rate over the study period
	scalar cc_orig = 0.03		//percent home value in origin location paid toward closing costs
	scalar cc_dest = 0.03		//percent home value in origin location paid toward closing costs
	scalar cc_rent = 0.5		//percent rent in destination paid as nonrefundable deposit
	scalar time_value_coll = 54		//opportunity cost per hour of moving college educated
	scalar time_value_nocoll = 34		//opportunity cost per hour of moving non college educated
	scalar fc_own = 1340		//fixed cost of move for typical homeowner
	scalar fc_rent = 670		//fixed cost of move for typical renter
	scalar fc_outside = 5000	//cost to and from the outside (catch-all) alternative
	scalar disc_rate = 0.05		//discount rate
	scalar t_own = 8			//time until next move for typical homeowner
	scalar t_rent = 2			//time until next move for typical renter
	scalar pct_rent = 0.28		//percent of households that rent
	

**************************************************
************Loading data for populations*********
**************************************************

***Bachelors and no-bachelors 2000 
clear
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2000_bach.csv"
keep if state == "Michigan"
replace state = "26"
egen nobachmale_2000 = rowtotal (gkt001 - gkt012)
egen bachmale_2000 = rowtotal (gkt013 - gkt016)
egen nobachfemale_2000 = rowtotal (gkt017 - gkt028)
egen bachfemale_2000 = rowtotal (gkt029 - gkt032)
gen bach25 = bachfemale_2000 + bachmale_2000
gen nobach25 = nobachmale_2000 + nobachfemale_2000
gen fips_orig = 26000 + countya
keep state county nobach25 bach25 fips_orig
rename state state_orig
rename county county_orig
rename bach25 bach25_orig
rename nobach25 nobach25_orig
tempfile pop_orig
save `pop_orig'

***Bachelors and no-bachelors 2010
getcensus s1501_c01_006 s1501_c01_015, sample(5) geography(county) years(2010) statefips(26) noerror
gen bach25 = s1501_c01_006*s1501_c01_015/100 //Converting percent bachelors degree or more into population. Before the 2015 ACS, educational attainment by degree was reported in percentages only
gen nobach25 = s1501_c01_006 - bach25
destring county, replace
gen fips = 26000 + county
keep state county bach25 nobach25 fips
foreach var in state county bach25 nobach25 fips{
	rename `var' `var'_dest
}
tempfile pop_dest
save `pop_dest'
clear

**************************************************
************Loading data for Housing and rents*********
**************************************************
**Housing value and rents 2005 
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/housing_info/rent_2000.csv", clear
keep if state == "Michigan"
rename hp3001 rent_value2000
replace rent_value2000 = rent_value2000*1.8
gen fips = 26000 + countya
keep state year fips rent_value2000
tempfile rent_2000
save `rent_2000'

import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/rent_2010_updated.csv", clear 
rename je0e001 rent_value2010
replace rent_value2010 = rent_value2010*1.4
keep if state == "Michigan"
gen fips = 26000 + countya
keep state year fips rent_value2010
tempfile rent_2010
save `rent_2010'

import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/housing_info/owner_2000.csv", clear
rename gb7001 own_value2000
replace own_value2000 = own_value2000*1.8
gen fips = 26000 + countya
keep if state == "Michigan"
keep state fips year own_value2000
tempfile owner_2000
save `owner_2000'

import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/owner2010.csv", clear
rename jfje001 own_value2010
replace own_value2010 = own_value2010*1.4
keep if state == "Michigan"
gen fips = 26000 + countya
keep state fips year own_value2010

merge 1:1 fips using `rent_2000',nogen
merge 1:1 fips using `rent_2010', nogen
merge 1:1 fips using `owner_2000', nogen

summ own_value2000 own_value2010 if own_value2010!=.
summ rent_value2000 rent_value2010 if rent_value2010!=.

gen own_value2005 = (own_value2000 + own_value2010)/2
gen rent_value2005 = (rent_value2010+rent_value2000)/2
replace state = "26"
rename state state_orig
gen state_dest = state_orig
rename fips fips_orig
gen fips_dest = fips_orig
replace own_value2005 = own_value2000*1.1571 if own_value2005 == .
replace rent_value2005 = rent_value2000*1.3193 if rent_value2005 == .
tempfile housing 
save `housing'

**ACS housing variables
getcensus dp04_0080 dp04_0089 dp04_0126 dp04_0134, sample(5) geography(county) years(2015) statefips(26) noerror
rename dp04_0080 units_own
rename dp04_0089 value
rename dp04_0126 units_rent
rename dp04_0134 rent
destring county, replace
gen fips_dest = 26000 + county
keep fips_dest units_own value units_rent rent
tempfile hous_variable
save `hous_variable'

**************************************************
***************Additional variables***************
**************************************************

***Household income
getcensus s1903_c01_001 s1903_c02_001, sample(5) geography(county) years(2015) statefips(26) noerror
rename s1903_c01_001 households
rename s1903_c02_001 income
destring state county, replace
gen fips = state*1000+county
keep fips households income
tempfile hh_income
save `hh_income'

***Household size
getcensus b25010_001, sample(5) geography(county) years(2015) statefips(26) noerror
rename b25010_001 householdsize
destring state county, replace
gen fips = state*1000+county
keep fips householdsize
tempfile hh_size
save `hh_size'

***Populations in 2000
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/DECENNIALDPSF42000.DP2-Data.csv", varnames(2) rowrange(2) colrange(:50) clear
gen fips= substr(geography,10,5)
keep if raceethnicgroup==1
rename numbereducationalattainmentpopul nobach25_2000
rename v41 bach25_2000
destring, replace force
replace nobach25_2000 = nobach25_2000-bach25_2000
keep fips bach25_2000 nobach25_2000
tempfile pop_2000
save `pop_2000'

***Air quality
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/county_fips.csv", clear 
keep if state == "Michigan"
tempfile fips
save `fips'
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/annual_aqi_by_county_2005.csv", clear
keep if state == "Michigan"
merge 1:1 county using `fips'
keep fips daysco daysno2 daysozone dayspm25 dayspm10
tempfile airquality
save `airquality'

***County ZCTAs
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/tab20_zcta520_county20_natl.txt", clear 
sort geoid_county_20
rename geoid_zcta5_20 zctas
rename geoid_county_20 fips
collapse (count) zctas, by(fips)
tempfile zctas
save `zctas'

*Demographics***
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/race_2000.csv",clear
keep if state == "Michigan"
rename fmr002 black
rename fmr001 white
egen total = rowtotal (white - fmr007)
gen other = total - (white+black)
gen percent_black2000 = black/total
gen percent_other2000 = other/total
gen fips = 26000 +countya
keep fips percent_black2000 percent_other2000
tempfile race2000
save `race2000'

getcensus C02003_001 C02003_003 C02003_004 C02003_005 C02003_006 C02003_007 C02003_008, sample(5) geography(county) years(2010) statefips(26) noerror clear
rename c02003_001 total
rename c02003_004 black
rename c02003_003 white 
gen other = total - (white+black)
gen percent_black2010 = black/total
gen percent_other2010 = other/total
destring county, replace
gen fips = 26000 + county
keep fips percent_black2010 percent_other2010

merge 1:1 fips using `race2000', nogen
gen percent_black = (percent_black2010+percent_black2000)/2
gen percent_other = (percent_other2000+percent_other2010)/2
keep fips percent_black percent_other
tempfile race
save `race'

**Age**
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/median_age.csv", clear 
keep if state == "Michigan"
rename adkme001 med_age
gen fips = 26000 + countya
keep fips med_age
tempfile med_age
save `med_age' 

*Temp****
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/January_2019.csv", rowrange(6) clear 
rename v2 CountyName 
rename v7 jan_temp
keep CountyName jan_temp
tempfile jan_temp
save `jan_temp'

import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/June_2019.csv", rowrange(6) clear 
rename v2 CountyName 
rename v7 june_temp
keep CountyName june_temp
tempfile june_temp
save `june_temp'

import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/US_FIPS_Codes.xls", sheet("3,142 U.S. Counties") cellrange(A2:D3144) firstrow clear
keep if State == "Michigan"
replace CountyName = "St. Joseph" in 75
replace CountyName = "St. Clair" in 74
replace CountyName = CountyName+ " County"
destring FIPSCounty, replace
gen fips = 26000 + FIPSCounty
keep State CountyName fips
tempfile fips
save `fips'

merge 1:m CountyName using `jan_temp', nogen
merge 1:m CountyName using `june_temp', nogen
tempfile temp
save `temp'

*percent ag/cropland***
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2002agcrop.csv", clear
gen fips = 26000 + countyansi
rename value ag_crop
destring ag_crop, replace ignore(",") force
keep year ag_crop fips 
tempfile ag_crop
save `ag_crop'

***URBAN***
import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/PctUrbanRural_County.xls", sheet("Pct urban by county") firstrow clear
keep if STATENAME == "Michigan"
destring COUNTY, replace
gen fips = 26000 + COUNTY
gen pct_urban = POPPCT_URBAN/100
keep STATENAME pct_urban fips
tempfile urban
save `urban'

**GREAT LAKE DISTANCE**
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/great_lakes_distance.csv", clear 
tempfile distance
save `distance'

**COASTAL COUNTY***
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/coastal_county.csv", clear 
keep if stateabbrv == "MI"
rename geoid fips 
gen coastal = 1
keep fips coastal
tempfile coastal
save `coastal'

**METRO***
import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/list3.xls", sheet("CBSAs and CSAs December 2005 ") cellrange(A4:K1867) firstrow clear
keep if State == "Michigan"
destring Status1metro2micro,replace
replace Status1metro2micro = 0 if Status1metro2micro == 2
rename Status1metro2micro metro
rename FIPS fips
destring fips, replace
keep metro fips 
tempfile metro
save `metro'

***WATER***
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2000_bach.csv", clear
keep if state == "Michigan"
gen pct_water = areawatr/arealand
gen fips = 26000 + countya
keep fips pct_water arealand
tempfile water
save `water'

gen power_plant = 0
replace power_plant = 1 if fips == 26021 
replace power_plant = 1 if fips == 26027 
replace power_plant = 1 if fips == 26159 
replace power_plant = 1 if fips == 26091 
replace power_plant = 1 if fips == 26115 
replace power_plant = 1 if fips == 26163 
replace power_plant = 1 if fips == 26161 
replace power_plant = 1 if fips == 26005 
replace power_plant = 1 if fips == 26077 
replace power_plant = 1 if fips == 26161 

replace power_plant = 0 if power_plant == .
drop if fips == 26000

**************************************************
****************Loading distances*****************
**************************************************
use "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/distance data MI.dta", clear
gen travel_time = movedistance/40
gen fips_dest = 26000 + county_dest
gen fips_orig = 26000 + county_orig
tempfile dist
save `dist'

**************************************************
********************Merging***********************
**************************************************
use `pop_dest', clear
merge 1:1 state_dest fips_dest using `housing', nogen
set obs `=_N+1'
drop fips_orig
drop state_orig
rename own_value2005 value_dest
rename rent_value2005 rent_dest

tempfile destinations
save `destinations'

use `pop_orig', clear
merge 1:1 state_orig fips_orig using `housing', nogen
set obs `=_N+1'
drop fips_dest
drop state_dest
rename own_value2005 value_orig
rename rent_value2005 rent_orig
drop county_orig

cross using `destinations'
destring, replace

merge m:1 fips_dest using `hous_variable',nogen
replace state_dest = 999 if fips_dest== .
replace fips_dest = 999 if fips_dest==.
replace state_orig = 999 if fips_orig==.
replace fips_orig = 999 if fips_orig==.
**************************************************
*************Calculating move costs***************
**************************************************

merge 1:1 state_dest fips_dest state_orig fips_orig using `dist', nogen keep(1 3)

*COLLEGE EDUCATED*

gen coll_movecost_own = fc_own + cc_orig*value_orig*(units_own)/(units_own + units_rent) + cc_dest*value_dest*(units_own)/(units_own+units_rent)

gen coll_movecost_rent = fc_rent + cc_rent*rent_dest*(units_rent)/(units_own+units_rent)

replace coll_movecost_own = fc_outside if state_orig==999|state_dest==999

replace coll_movecost_rent = fc_outside if state_orig==999|state_dest==999

gen coll_movecost = (time_value_coll*travel_time/60 + coll_movecost_own)/((1-1/(1+disc_rate)^t_own)/disc_rate) + (time_value_coll*travel_time/60 + coll_movecost_rent)/((1-1/(1+disc_rate)^t_rent)/disc_rate)

replace coll_movecost=0 if fips_orig==fips_dest

*NO COLLEGE EDUCATION*

gen nocoll_movecost_own = fc_own + cc_orig*value_orig*(units_own)/(units_own + units_rent) + cc_dest*value_dest*(units_own)/(units_own+units_rent)

gen nocoll_movecost_rent = fc_rent + cc_rent*rent_dest*(units_rent)/(units_own+units_rent)

replace nocoll_movecost_own = fc_outside if state_orig==999|state_dest==999
replace nocoll_movecost_rent = fc_outside if state_orig==999|state_dest==999

gen nocoll_movecost = (time_value_nocoll*travel_time/60 + nocoll_movecost_own)/((1-1/(1+disc_rate)^t_own)/disc_rate) + (time_value_nocoll*travel_time/60 + nocoll_movecost_rent)/((1-1/(1+disc_rate)^t_rent)/disc_rate)

replace nocoll_movecost=0 if fips_orig==fips_dest


**************************************************
**************Save data for stage 1***************
**************************************************
preserve
keep state_orig fips_orig bach25_orig nobach25_orig state_dest fips_dest bach25_dest nobach25_dest nocoll_movecost coll_movecost

save "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/2000-2010 Data for sorting model stage 1.dta", replace
restore

**************************************************
**************Save data for stage 2***************
**************************************************
gen fips = fips_orig
collapse state_orig fips_orig bach25_orig nobach25_orig value_orig rent_orig, by(fips)
rename bach25_orig bach25_2010
rename nobach25_orig nobach25_2010
gen housing_cost = (1-pct_rent)*value_orig/20 + pct_rent*rent_orig*12
replace fips = 999999 if fips == 999
merge 1:1 fips using `pop_2000', keep(1 3) nogen
merge 1:1 fips using `hh_size', keep(1 3) nogen
merge 1:1 fips using `hh_income', keep(1 3) nogen
merge 1:m fips using `race', nogen
merge 1:m fips using `med_age', nogen 
merge 1:m fips using `temp', nogen
merge 1:m fips using `ag_crop', nogen
merge 1:m fips using `urban', nogen
merge 1:m fips using `distance', keep(1 3) nogen
merge 1:m fips using `water', nogen
merge 1:m fips using `coastal', nogen
merge 1:m fips using `metro', nogen
merge 1:1 fips using `airquality', keep(1 3) nogen
merge 1:1 fips using `zctas', keep(1 3) nogen
replace coastal = 0 if coastal == .
gen percent_agcrop = ag_crop/arealand
replace percent_agcrop = 0 if percent_agcrop == .
replace metro = 0 if metro == .
drop if fips == 26000

sum bach25_2000 if fips==8001|fips==8013|fips==8059|fips==8123 //Adjusting for creation of Broomfield County; see https://www.ddorn.net/data/FIPS_County_Code_Changes.pdf
scalar totbach = r(mean)*r(N)
sum nobach25_2000 if fips==8001|fips==8013|fips==8059|fips==8123
scalar totnobach = r(mean)*r(N)
foreach var in bach25_2000 nobach25_2000{
	replace `var' = round(`var'*(1-15870/363857)) if fips==8001
	replace `var' = round(`var'*(1-21512/291288)) if fips==8013
	replace `var' = round(`var'*(1-1726/527056)) if fips==8059
	replace `var' = round(`var'*(1-69/18936)) if fips==80123
}
sum bach25_2000 if fips==8001|fips==8013|fips==8059|fips==8123
replace bach25_2000 = totbach-r(mean)*r(N) if fips==8014
sum nobach25_2000 if fips==8001|fips==8013|fips==8059|fips==8123
replace nobach25_2000 = totnobach-r(mean)*r(N) if fips==8014
save "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/2000-2010 Data for sorting model stage 2.dta", replace
