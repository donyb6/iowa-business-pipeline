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


SELECT home_office, ho_address_1, ho_address_2, ho_city, ho_zip, ho_state, ho_country
FROM silver_active_iowa_business
WHERE ho_country REGEXP '^[0-9]+$'; -- ho_country entries which are numbers must rather be in the ho_zip entry