SELECT *
FROM gold_dim_corporation_type;

SELECT *
FROM gold_dim_date;

SELECT *
FROM gold_dim_ho_location;

SELECT *
FROM gold_dim_ra_location;

SELECT *
FROM gold_fact_business;

CREATE OR REPLACE VIEW gold_active_iowa_business AS
SELECT
    f.corp_number,
    f.legal_name,
    f.registered_agent,
    f.has_ho_address,

    d.full_date AS effective_date,
    d.year,
    d.quarter,
    d.month_name,
    d.day_of_week,
    d.is_future,

    ct.corporation_type,

    ra.address_1 AS ra_address_1,
    ra.address_2 AS ra_address_2,
    ra.city      AS ra_city,
    ra.state     AS ra_state,
    ra.zip       AS ra_zip,
    ra.latitude  AS ra_latitude,
    ra.longitude AS ra_longitude,

    ho.address_1 AS ho_address_1,
    ho.address_2 AS ho_address_2,
    ho.city      AS ho_city,
    ho.state     AS ho_state,
    ho.zip       AS ho_zip,
    ho.country   AS ho_country,
    ho.latitude  AS ho_latitude,
    ho.longitude AS ho_longitude

FROM gold_fact_active_business AS f
LEFT JOIN gold_dim_date AS d
    ON f.date_key = d.date_key
LEFT JOIN gold_dim_corporation_type AS ct
    ON f.corporation_type_key = ct.corporation_type_key
LEFT JOIN gold_dim_ra_location AS ra
    ON f.ra_location_key = ra.ra_location_key
LEFT JOIN gold_dim_ho_location AS ho
    ON f.ho_location_key = ho.ho_location_key;

-- join all tables as one
SELECT
    f.corp_number,
    f.legal_name,
    f.registered_agent,
    f.has_ho_address,

    d.full_date AS effective_date,
    d.year,
    d.quarter,
    d.month_name,
    d.day_of_week,
    d.is_future,

    ct.corporation_type,

    ra.address_1 AS ra_address_1,
    ra.address_2 AS ra_address_2,
    ra.city      AS ra_city,
    ra.state     AS ra_state,
    ra.zip       AS ra_zip,
    ra.latitude  AS ra_latitude,
    ra.longitude AS ra_longitude,

    ho.address_1 AS ho_address_1,
    ho.address_2 AS ho_address_2,
    ho.city      AS ho_city,
    ho.state     AS ho_state,
    ho.zip       AS ho_zip,
    ho.country   AS ho_country,
    ho.latitude  AS ho_latitude,
    ho.longitude AS ho_longitude

FROM gold_fact_active_business AS f
LEFT JOIN gold_dim_date AS d
    ON f.date_key = d.date_key
LEFT JOIN gold_dim_corporation_type AS ct
    ON f.corporation_type_key = ct.corporation_type_key
LEFT JOIN gold_dim_ra_location AS ra
    ON f.ra_location_key = ra.ra_location_key
LEFT JOIN gold_dim_ho_location AS ho
    ON f.ho_location_key = ho.ho_location_key;

SELECT COUNT(*) AS total_number_of_active_businesses
FROM gold_fact_active_business AS f;

-- im selecting from gold_active_iowa_business because it is a view that joins all the necessary tables together. hence, it is easier to write queries instead of using long joins

-- business count by corporation type
SELECT corporation_type, COUNT(*) AS business_count
FROM gold_active_iowa_business
GROUP BY corporation_type
ORDER BY business_count DESC;

-- registrations by year
SELECT year, COUNT(*) AS registrations_by_year
FROM gold_active_iowa_business
WHERE year IS NOT NULL
GROUP BY year
ORDER BY year;

SELECT month_name, COUNT(*) AS registrations
FROM gold_active_iowa_business
WHERE month_name IS NOT NULL
GROUP BY month_name
ORDER BY FIELD(month_name, 'January','February','March','April','May','June',
                            'July','August','September','October','November','December');

-- registrations by month name per year
SELECT year, month_name, COUNT(*) AS registrations_by_month
FROM gold_active_iowa_business
WHERE year IS NOT NULL AND month_name IS NOT NULL
GROUP BY year, month_name
ORDER BY year, month_name;

-- top 10 cities by ra location
SELECT ra_city, COUNT(*) AS business_count
FROM gold_active_iowa_business
WHERE ra_city IS NOT NULL
GROUP BY ra_city
ORDER BY business_count DESC
LIMIT 10;

-- top 10 cities by ho location
SELECT ho_city, COUNT(*) AS business_count
FROM gold_active_iowa_business
WHERE ho_city IS NOT NULL
GROUP BY ho_city
ORDER BY business_count DESC
LIMIT 10;

-- businesses with ho address or not
SELECT has_ho_address, COUNT(*) AS business_count
FROM gold_active_iowa_business
GROUP BY has_ho_address;

SELECT ra_state, COUNT(*) AS business_count
FROM gold_active_iowa_business
WHERE ra_state IS NOT NULL 
GROUP BY ra_state
ORDER BY business_count DESC; -- from this query, there are states which should be city names, this is a data quality issue. i will need to clean again but from the silver layer