DROP TABLE IF EXISTS silver_active_iowa_business;

SELECT *
FROM bronze_active_iowa_business;

CREATE TABLE silver_active_iowa_business AS
SELECT * FROM bronze_active_iowa_business;

SELECT *
FROM silver_active_iowa_business;

-- properly format the date fields
SELECT effective_date, STR_TO_DATE(effective_date, '%Y-%m-%d') AS date_fix
FROM silver_active_iowa_business;

UPDATE silver_active_iowa_business
SET effective_date = STR_TO_DATE(effective_date, '%Y-%m-%d')
WHERE effective_date IS NOT NULL;

-- alter the effective_date field to be of type date
ALTER TABLE silver_active_iowa_business
MODIFY effective_date DATE;

-- trim and replace with blanks in all the categorical fields to remove any leading or trailing spaces or irregularities
SELECT DISTINCT corporation_type, TRIM(corporation_type) AS trimmed_corporation_type
FROM silver_active_iowa_business;

UPDATE silver_active_iowa_business
SET corporation_type = TRIM(corporation_type);

SELECT legal_name, TRIM(legal_name) AS trimmed_legal_name
FROM silver_active_iowa_business;

UPDATE silver_active_iowa_business
SET legal_name = TRIM(legal_name);

SELECT legal_name, REPLACE(legal_name, '"', '') AS trimmed_legal_name
FROM silver_active_iowa_business
WHERE legal_name LIKE '"%' OR legal_name LIKE '%"' OR legal_name LIKE '"%"';

UPDATE silver_active_iowa_business
SET legal_name = REPLACE(legal_name, '"', '')
WHERE legal_name LIKE '"%' OR legal_name LIKE '%"' OR legal_name LIKE '"%"';

UPDATE silver_active_iowa_business
SET registered_agent = TRIM(registered_agent);

/*
SELECT registered_agent, REPLACE(registered_agent, '"', '') AS trimmed_registered_agent
FROM silver_active_iowa_business
WHERE registered_agent LIKE '%"%';

UPDATE silver_active_iowa_business
SET registered_agent = REPLACE(registered_agent, '"', '')
WHERE registered_agent LIKE '%"';*/

SELECT ra_address_1, REPLACE(ra_address_1, '"', '') AS ra_1_cleaned
FROM silver_active_iowa_business
WHERE ra_address_1 LIKE '"%' OR ra_address_1 LIKE '%"' OR ra_address_1 LIKE '"%"';

SELECT ra_address_2, REPLACE(ra_address_2, '"', '') AS ra_2_cleaned
FROM silver_active_iowa_business
WHERE ra_address_2 LIKE '"%' OR ra_address_2 LIKE '%"' OR ra_address_2 LIKE '"%"';

UPDATE silver_active_iowa_business
SET ra_address_1 = REPLACE(ra_address_1, '"', '')
WHERE ra_address_1 LIKE '"%' OR ra_address_1 LIKE '%"' OR ra_address_1 LIKE '"%"';

UPDATE silver_active_iowa_business
SET ra_city = TRIM(ra_city);

UPDATE silver_active_iowa_business
SET ra_state = TRIM(ra_state);

UPDATE silver_active_iowa_business
SET ra_zip = TRIM(ra_zip);

UPDATE silver_active_iowa_business
SET home_office = TRIM(home_office);

UPDATE silver_active_iowa_business
SET ho_city = TRIM(ho_city);

UPDATE silver_active_iowa_business
SET ho_state = TRIM(ho_state);

UPDATE silver_active_iowa_business
SET ho_zip = TRIM(ho_zip);

SELECT ho_city, REPLACE(ho_city, '"', '') AS ho_city_cleaned
FROM silver_active_iowa_business
WHERE ho_city LIKE '"%' OR ho_city LIKE '%"' OR ho_city LIKE '"%"';

UPDATE silver_active_iowa_business
SET ho_city = REPLACE(ho_city, '"', '')
WHERE ho_city LIKE '"%' OR ho_city LIKE '%"' OR ho_city LIKE '"%"';


-- check numerical entries in all categorical fields
SELECT ra_address_1, ra_address_2, ra_city, ra_zip, ra_state
FROM silver_active_iowa_business
WHERE ra_address_1 REGEXP '^[0-9]+$'; -- ra_address_1 entries which are numbers between 3 to 12 digits. this is a data quality issue

SELECT ra_address_1, ra_address_2, ra_city, ra_zip, ra_state
FROM silver_active_iowa_business
WHERE ra_address_2 REGEXP '^[0-9]+$'; -- ra_address_2 entries which are numbers between 1 to 10 digits. this is a data quality issue

SELECT ra_address_1, ra_address_2, ra_city, ra_zip, ra_state
FROM silver_active_iowa_business
WHERE ra_city REGEXP '^[0-9]+$'; -- ra_city entries which are numbers must rather be in the ra_zip entry, however, ra_zip has them already. theres one row which has no entries in the all ra fields except ra city and has 6 digits in ra_city, so this is a data quality issue

SELECT ra_address_1, ra_address_2, ra_city, ra_zip, ra_state
FROM silver_active_iowa_business
WHERE ra_state REGEXP '^[A-Za-z]{3,}$'; -- ra_state entries which are not 2 letter state codes must rather be in the ra_city and the corresponding ra_city entries are null. this is a data quality issue

SELECT ra_address_1, ra_address_2, ra_city, ra_zip, ra_state
FROM silver_active_iowa_business
WHERE ra_city REGEXP '^[A-Za-z]{2}$'; -- from this, ra_city are in ra_zip. but, ra_city entries (CL, DA, LE) must be in ra_city. also, ra_address_2 (MUSCATINE, RICKARDSVILLE, WATERLOO, DAVENPORT, WINTERSET, DES MOINES, ELMA, LENOX, IOWA CITY, CLIVE, HARLAN, WEST DES MOINES, LENOX, BETTENDORF, LAMOTTE, ROCK VALLEY, DES MOINES, WEST DES MOINES, CRESCO, AMES, LENOX, LAWLER), has ra_city entries from this query. another data quality issue


SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE home_office REGEXP '^[0-9]+$'; -- home_office entries which are numbers must rather be in the ho_zip entry. also the corresponding ho_zip are null while ho_country has the same entries as home_office. this is a data quality issue

SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE ho_address_1 REGEXP '^[0-9]+$'; -- ho_address_1 has numerical entries just like ra_address_1. this is a data quality issue

SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE ho_address_2 REGEXP '^[0-9]+$'; -- ho_address_2 has numerical entries just like ra_address_2. this is a data quality issue

SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE ho_city REGEXP '^[0-9]+$'; -- ho_city has numerical entries which are also in ho_zip. however ho_city 50213 has a null ho_zip. this is a data quality issue

SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE ho_country REGEXP '^[0-9]+$'; -- ho_country has numerical entries as home_office while ho_zip is null. this is a data quality issue.

SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE ho_state REGEXP '^[A-Za-z]{3,}$'; -- ho_state has entries which should be in ho_city while ho_city is null. this is a data quality issue.

SELECT ho_address_1, ho_address_2, ho_city, ho_zip, ho_state
FROM silver_active_iowa_business
WHERE ho_city REGEXP '^[A-Za-z]{2}$'; -- ho city entries (MO, NE, OP, TA, UP, DM, NY, WE ,CH) are partially ho_city entries which should be corrected in full, but also, some ho_address_2(TIPTON, DEEP RIVER, ANKENY, DES MOINES, KELLEY, IOWA CITY, CEDAR FALLS, PERRY, BELLEVUE, BELLEVUE, RIPPEY, LENOX) entries must be in ho_city. this is a data quality issue.

-- update ra and ho fields to correct the data quality issues found.


-- prep ra_location and ho_location fields for geocoding
SELECT ho_location, ra_location
FROM silver_active_iowa_business;

UPDATE silver_active_iowa_business
SET ho_location = TRIM(REPLACE(ho_location, '"', '')),
    ra_location = TRIM(REPLACE(ra_location, '"', ''));

SELECT ho_location, ra_location
FROM silver_active_iowa_business
WHERE ho_location NOT REGEXP '^POINT \\(-?[0-9.]+ -?[0-9.]+\\)$'
   OR ra_location NOT REGEXP '^POINT \\(-?[0-9.]+ -?[0-9.]+\\)$'; -- check for any non-point entries in the ho_location and ra_location fields.  rows returned from this query will be data quality issues that need to be corrected before geocoding.


SELECT ho_location,
       ST_GeomFromText(ho_location) AS ho_test
FROM silver_active_iowa_business;

SELECT ra_location, 
        ST_GeomFromText(ra_location) AS ra_test
FROM silver_active_iowa_business;

ALTER TABLE silver_active_iowa_business
ADD ho_point POINT,
ADD ra_point POINT;

UPDATE silver_active_iowa_business
SET 
  ho_point = ST_GeomFromText(ho_location),
  ra_point = ST_GeomFromText(ra_location)
WHERE ho_location IS NOT NULL
  AND ra_location IS NOT NULL;

ALTER TABLE silver_active_iowa_business
DROP COLUMN ho_location,
DROP COLUMN ra_location;