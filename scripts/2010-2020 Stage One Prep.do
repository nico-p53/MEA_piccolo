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

***Bachelors and no-bachelors 2010
getcensus s1501_c01_006 s1501_c01_015, sample(5) geography(county) years(2010) statefips(26) noerror
gen bach25 = s1501_c01_006*s1501_c01_015/100 //Converting percent bachelors degree or more into population. Before the 2015 ACS, educational attainment by degree was reported in percentages only
gen nobach25 = s1501_c01_006 - bach25
keep state county bach25 nobach25
foreach var in state county bach25 nobach25{
	rename `var' `var'_orig
}
tempfile pop_orig
save `pop_orig'

***Bachelors and no-bachelors 2019
getcensus s1501_c01_006 s1501_c01_015, sample(5) geography(county) years(2019) statefips(26) noerror
rename s1501_c01_015e bach25
gen nobach25 = s1501_c01_006 - bach25
keep state county bach25 nobach25
foreach var in state county bach25 nobach25{
	rename `var' `var'_dest
}
tempfile pop_dest
save `pop_dest'
clear

**************************************************
************Loading data for Housing and rents*********
**************************************************

***Housing value and rents origin
getcensus dp04_0080 dp04_0089 dp04_0126 dp04_0134, sample(5) geography(county) years(2015) statefips(26) noerror
rename dp04_0080 units_own
rename dp04_0089 value
rename dp04_0126 units_rent
rename dp04_0134 rent
replace value = inflate*value
replace rent = inflate*rent
keep state county units_own value units_rent rent
foreach var in state county units_own value units_rent rent{
	rename `var' `var'_orig
}
tempfile hous_orig
save `hous_orig'

***Housing value and rents destination
getcensus dp04_0080 dp04_0089 dp04_0126 dp04_0134, sample(5) geography(county) years(2015) statefips(26) noerror
rename dp04_0080 units_own
rename dp04_0089 value
rename dp04_0126 units_rent
rename dp04_0134 rent
keep state county units_own value units_rent rent
foreach var in state county units_own value units_rent rent{
	rename `var' `var'_dest
}
tempfile hous_dest
save `hous_dest'
clear

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
tempfile fips
save `fips'
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/annual_aqi_by_county_2015.csv", clear
merge 1:1 state county using `fips'
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
getcensus C02003_001 C02003_003 C02003_004 C02003_005 C02003_006 C02003_007 C02003_008, sample(5) geography(county) years(2015) statefips(26) noerror clear
rename c02003_001 total
rename c02003_004 black
rename c02003_003 white 
gen other = total - (white+black)
gen percent_black = black/total
gen percent_other = other/total
destring county, replace
gen fips = 26000 + county
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
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/Michigan Cropland.csv", rowrange(6) clear
keep if year == 2017 
gen fips = 26000 + countyansi
rename value ag_crop
destring ag_crop, replace ignore(",") force
keep year ag_crop fips 
tempfile ag_crop
save `ag_crop'

***URBAN***
import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2020_UA_COUNTY.xlsx", sheet("2020_UA_COUNTY") firstrow clear
keep if STATE_NAME == "Michigan"
gen percent_urban = ALAND_URB/ALAND_COU
destring COUNTY, replace
gen fips = 26000 + COUNTY
keep percent_urban fips
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
import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/metro_area.xls", sheet("List 1") cellrange(A3:L1923) firstrow clear
keep if FIPSStateCode == "26"
destring FIPSCountyCode, replace
gen fips = 26000+FIPSCountyCode
keep if MetropolitanMicropolitanStatis == "Metropolitan Statistical Area"
gen metro = 1
keep fips metro 
tempfile metro
save `metro'

***WATER***
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2020_Gaz_counties_national.txt", clear
keep if usps == "MI"
gen percent_water = awater/(awater+aland)
rename geoid fips
keep fips aland awater percent_water
tempfile water
save `water'

**MERGE**
//merge 1:m fips using `race', nogen
//merge 1:m fips using `med_age', nogen 
//merge 1:m fips using `temp', nogen
//merge 1:m fips using `ag_crop', nogen
//merge 1:m fips using `urban', nogen
//merge 1:m fips using `distance', keep(1 3) nogen
//merge 1:m fips using `coastal', nogen
//merge 1:m fips using `metro', nogen

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

**************************************************
****************Loading distances*****************
**************************************************
use "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/distance data MI.dta", clear
gen travel_time = movedistance/40
tempfile dist
save `dist'

**************************************************
********************Merging***********************
**************************************************
use `pop_dest', clear
merge 1:1 state_dest county_dest using `hous_dest', nogen
set obs `=_N+1'
replace state_dest = "999" if county_dest==""
replace county_dest = "999" if county_dest==""
tempfile destinations
save `destinations'

use `pop_orig', clear
merge 1:1 state_orig county_orig using `hous_orig', nogen
set obs `=_N+1'
replace state_orig = "999" if county_orig==""
replace county_orig = "999" if county_orig==""

cross using `destinations'
destring, replace

**************************************************
*************Calculating move costs***************
**************************************************

*COLLEGE EDUCATED*
merge 1:1 state_dest county_dest state_orig county_orig using `dist', nogen

gen coll_movecost_own = fc_own + cc_orig*value_orig*(units_own_orig)/(units_own_orig + units_rent_orig) + cc_dest*value_dest*(units_own_dest)/(units_own_dest+units_rent_dest)

gen coll_movecost_rent = fc_rent + cc_rent*rent_dest*(units_rent_dest)/(units_own_dest+units_rent_dest)

replace coll_movecost_own = fc_outside if state_orig==999|state_dest==999

replace coll_movecost_rent = fc_outside if state_orig==999|state_dest==999

gen coll_movecost = (time_value_coll*travel_time/60 + coll_movecost_own)/((1-1/(1+disc_rate)^t_own)/disc_rate) + (time_value_coll*travel_time/60 + coll_movecost_rent)/((1-1/(1+disc_rate)^t_rent)/disc_rate)

replace coll_movecost=0 if county_orig==county_dest

*NO COLLEGE EDUCATION*
merge 1:1 state_dest county_dest state_orig county_orig using `dist', nogen

gen nocoll_movecost_own = fc_own + cc_orig*value_orig*(units_own_orig)/(units_own_orig + units_rent_orig) + cc_dest*value_dest*(units_own_dest)/(units_own_dest+units_rent_dest)

gen nocoll_movecost_rent = fc_rent + cc_rent*rent_dest*(units_rent_dest)/(units_own_dest+units_rent_dest)

replace nocoll_movecost_own = fc_outside if state_orig==999|state_dest==999
replace nocoll_movecost_rent = fc_outside if state_orig==999|state_dest==999

gen nocoll_movecost = (time_value_nocoll*travel_time/60 + nocoll_movecost_own)/((1-1/(1+disc_rate)^t_own)/disc_rate) + (time_value_nocoll*travel_time/60 + nocoll_movecost_rent)/((1-1/(1+disc_rate)^t_rent)/disc_rate)

replace nocoll_movecost=0 if county_orig==county_dest


**************************************************
**************Save data for stage 1***************
**************************************************
preserve
keep state_orig county_orig bach25_orig nobach25_orig state_dest county_dest bach25_dest nobach25_dest nocoll_movecost coll_movecost
save "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/2010-2020 Data for sorting model stage 1.dta", replace
restore

**************************************************
**************Save data for stage 2***************
**************************************************
gen fips = state_orig*1000+county_orig
collapse state_orig county_orig bach25_orig nobach25_orig value_orig rent_orig, by(fips)
rename bach25_orig bach25_2010
rename nobach25_orig nobach25_2010
gen housing_cost = (1-pct_rent)*value_orig/20 + pct_rent*rent_orig*12
merge 1:1 fips using `pop_2000', keep(1 3) nogen
merge 1:1 fips using `hh_size', keep(1 3) nogen
merge 1:1 fips using `hh_income', keep(1 3) nogen
merge 1:1 fips using `airquality', keep(1 3) nogen
merge 1:1 fips using `zctas', keep(1 3) nogen
merge 1:m fips using `race', nogen
merge 1:m fips using `med_age', nogen 
merge 1:m fips using `temp', nogen
merge 1:m fips using `ag_crop', nogen
merge 1:m fips using `urban', nogen
merge 1:m fips using `distance', keep(1 3) nogen
merge 1:m fips using `water', nogen
merge 1:m fips using `coastal', nogen
merge 1:m fips using `metro', nogen
replace coastal = 0 if coastal == .
gen percent_agcrop = ag_crop/aland
replace percent_agcrop = 0 if percent_agcrop == .
replace metro = 0 if metro == .
drop if fips == 26000
drop if fips == .

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

save "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/2010-2020 Data for sorting model stage 2.dta", replace


