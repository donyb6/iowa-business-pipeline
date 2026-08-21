SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS gold_active_iowa_business;

DROP TABLE IF EXISTS gold_fact_active_business;
DROP TABLE IF EXISTS gold_dim_date;
DROP TABLE IF EXISTS gold_dim_corporation_type;
DROP TABLE IF EXISTS gold_dim_ra_location;
DROP TABLE IF EXISTS gold_dim_ho_location;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE gold_dim_date (
    date_key INT AUTO_INCREMENT PRIMARY KEY,
    full_date DATE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    day_of_week VARCHAR(20),
    is_future BOOLEAN
);

INSERT INTO gold_dim_date (full_date, year, quarter, month, month_name, day, day_of_week, is_future)
SELECT DISTINCT
    effective_date,
    YEAR(effective_date),
    QUARTER(effective_date),
    MONTH(effective_date),
    MONTHNAME(effective_date),
    DAY(effective_date),
    DAYNAME(effective_date),
    effective_date > CURDATE()
FROM silver_active_iowa_business
WHERE effective_date IS NOT NULL;


CREATE TABLE gold_dim_corporation_type (
    corporation_type_key INT AUTO_INCREMENT PRIMARY KEY,
    corporation_type VARCHAR(255)
);

INSERT INTO gold_dim_corporation_type (corporation_type)
SELECT DISTINCT corporation_type
FROM silver_active_iowa_business
WHERE corporation_type IS NOT NULL;

CREATE TABLE gold_dim_ra_location (
    ra_location_key INT AUTO_INCREMENT PRIMARY KEY,
    address_1 VARCHAR(255),
    address_2 VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip VARCHAR(255),
    country VARCHAR(255),
    latitude VARCHAR(255),
    longitude VARCHAR(255)
);

INSERT INTO gold_dim_ra_location (address_1, address_2, city, state, zip, latitude, longitude)
SELECT DISTINCT
    ra_address_1_corrected,
    ra_address_2_corrected,
    ra_city_corrected,
    ra_state_corrected,
    ra_zip_corrected,
    ra_latitude,
    ra_longitude
FROM silver_active_iowa_business;


CREATE TABLE gold_dim_ho_location (
    ho_location_key INT AUTO_INCREMENT PRIMARY KEY,
    address_1 VARCHAR(255),
    address_2 VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zip VARCHAR(255),
    country VARCHAR(255),
    latitude VARCHAR(255),
    longitude VARCHAR(255)
);

INSERT INTO gold_dim_ho_location (address_1, address_2, city, state, zip, country, latitude, longitude)
SELECT DISTINCT
    ho_address_1_corrected,
    ho_address_2_corrected,
    ho_city_corrected,
    ho_state_corrected,
    ho_zip_corrected,
    ho_country_corrected,
    ho_latitude,
    ho_longitude
FROM silver_active_iowa_business;


CREATE TABLE gold_fact_active_business (
    corp_number VARCHAR(255) PRIMARY KEY,
    date_key INT,
    corporation_type_key INT,
    ra_location_key INT,
    ho_location_key INT,
    legal_name VARCHAR(255),
    registered_agent VARCHAR(255),
    has_ho_address BOOLEAN,
    FOREIGN KEY (date_key) REFERENCES gold_dim_date(date_key),
    FOREIGN KEY (corporation_type_key) REFERENCES gold_dim_corporation_type(corporation_type_key),
    FOREIGN KEY (ra_location_key) REFERENCES gold_dim_ra_location(ra_location_key),
    FOREIGN KEY (ho_location_key) REFERENCES gold_dim_ho_location(ho_location_key)
);

INSERT INTO gold_fact_active_business
SELECT
    s.corp_number,
    d.date_key,
    ct.corporation_type_key,
    ra_loc.ra_location_key,
    ho_loc.ho_location_key,
    s.legal_name,
    s.registered_agent,
    CASE
        WHEN s.ho_address_1_corrected IS NOT NULL OR s.ho_city_corrected IS NOT NULL THEN TRUE
        ELSE FALSE
    END
FROM silver_active_iowa_business AS s
LEFT JOIN gold_dim_date AS d
    ON d.full_date <=> s.effective_date
LEFT JOIN gold_dim_corporation_type AS ct
    ON ct.corporation_type = s.corporation_type
LEFT JOIN gold_dim_ra_location AS ra_loc
    ON  ra_loc.address_1 <=> s.ra_address_1_corrected
    AND ra_loc.address_2 <=> s.ra_address_2_corrected
    AND ra_loc.city      <=> s.ra_city_corrected
    AND ra_loc.state     <=> s.ra_state_corrected
    AND ra_loc.zip       <=> s.ra_zip_corrected
    AND ra_loc.latitude  <=> s.ra_latitude
    AND ra_loc.longitude <=> s.ra_longitude
LEFT JOIN gold_dim_ho_location AS ho_loc
    ON  ho_loc.address_1 <=> s.ho_address_1_corrected
    AND ho_loc.address_2 <=> s.ho_address_2_corrected
    AND ho_loc.city      <=> s.ho_city_corrected
    AND ho_loc.state     <=> s.ho_state_corrected
    AND ho_loc.zip       <=> s.ho_zip_corrected
    AND ho_loc.country   <=> s.ho_country_corrected
    AND ho_loc.latitude  <=> s.ho_latitude
    AND ho_loc.longitude <=> s.ho_longitude;


-- view the gold schema
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

SELECT * FROM gold_active_iowa_business;