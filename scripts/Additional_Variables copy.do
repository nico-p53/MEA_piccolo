clear
*Demographics***
//C02003_001 total race
//C02003_003 white
//C02003_004 black
//C02003_005 native
//C02003_006 asian 
//C02003_007 pac islander
//C02003_008 other
//C03001_003 hispanic
//C03001_001 total
getcensus C02003_001 C02003_003 C02003_004 C02003_005 C02003_006 C02003_007 C02003_008, sample(5) geography(county) years(2019) statefips(26) noerror clear
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
//getcensus catalog, product(ST) to see different variables
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/median_age.csv", clear 
keep if state == "Michigan"
rename adkme001 med_age
gen fips = 26000 + countya
keep fips med_age
tempfile med_age
save `med_age' 

*Temp****
//https://www.ncei.noaa.gov/access/monitoring/climate-at-a-glance/county/mapping/20/tavg/202001/1/value
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
//https://quickstats.nass.usda.gov/#5C37FE1C-8CEF-36B9-A4C9-C9DF9FCA8542
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/Michigan Cropland.csv", rowrange(6) clear
keep if year == 2017 
gen fips = 26000 + countyansi
rename value ag_crop
destring ag_crop, replace ignore(",") force
keep year ag_crop fips 
tempfile ag_crop
save `ag_crop'

***URBAN*** https://www.census.gov/programs-surveys/geography/guidance/geo-areas/urban-rural.html 
import excel "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/2020_UA_COUNTY.xlsx", sheet("2020_UA_COUNTY") firstrow clear
keep if STATE_NAME == "Michigan"
gen percent_urban = ALAND_URB/ALAND_COU
destring COUNTY, replace
gen fips = 26000 + COUNTY
keep percent_urban fips
tempfile urban
save `urban'

**GREAT LAKE DISTANCE**
//Data from Tim
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/great_lakes_distance.csv", clear 
tempfile distance
save `distance'

**COASTAL COUNTY***
///https://coast.noaa.gov/digitalcoast/data/ : under ACS for US Coastal Shoreline Counties///
import delimited "/Users/nicolinapiccolo/Desktop/ENVS 391 /Data/coastal_county.csv", clear 
keep if stateabbrv == "MI"
rename geoid fips 
gen coastal = 1
keep fips coastal
tempfile coastal
save `coastal'

**METRO***
//https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/historical-delineation-files.html
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
merge 1:m fips using `race', nogen
merge 1:m fips using `med_age', nogen 
merge 1:m fips using `temp', nogen
merge 1:m fips using `ag_crop', nogen
merge 1:m fips using `urban', nogen
merge 1:m fips using `distance', keep(1 3) nogen
merge 1:m fips using `coastal', nogen
merge 1:m fips using `metro', nogen

gen percent_agcrop = ag_crop/aland

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
replace metro = 0 if metro == .
replace coastal = 0 if coastal == .
replace percent_agcrop = 0 if percent_agcrop == .
drop if fips == 26000

keep fips percent_water percent_black percent_other med_age june_temp jan_temp percent_urban percent_agcrop power_plant coastal metro great_lake_dist cbsa_dist

save "/Users/nicolinapiccolo/Desktop/ENVS 391 /Do Files/stage 2 location attributes.dta", replace
