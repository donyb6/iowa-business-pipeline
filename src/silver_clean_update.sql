ALTER TABLE silver_active_iowa_business

-- ra
ADD COLUMN ra_address_1_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ra_address_1_corrected VARCHAR(255),

ADD COLUMN ra_address_2_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ra_address_2_corrected VARCHAR(255),

ADD COLUMN ra_city_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ra_city_corrected VARCHAR(255),

ADD COLUMN ra_zip_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ra_zip_corrected VARCHAR(20),

ADD COLUMN ra_state_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ra_state_corrected VARCHAR(2),

-- ho
ADD COLUMN home_office_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN home_office_corrected VARCHAR(20),

ADD COLUMN ho_address_1_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ho_address_1_corrected VARCHAR(255),

ADD COLUMN ho_address_2_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ho_address_2_corrected VARCHAR(255),

ADD COLUMN ho_city_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ho_city_corrected VARCHAR(255),

ADD COLUMN ho_zip_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ho_zip_corrected VARCHAR(20),

ADD COLUMN ho_state_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ho_state_corrected VARCHAR(2),

ADD COLUMN ho_country_altered BOOLEAN DEFAULT FALSE,
ADD COLUMN ho_country_corrected VARCHAR(255);

UPDATE silver_active_iowa_business
SET
    ra_address_1_altered = TRUE,
    ra_address_1_corrected = NULL
WHERE ra_address_1 REGEXP '^[0-9]+$';


UPDATE silver_active_iowa_business
SET
    ra_address_2_altered = TRUE,
    ra_address_2_corrected = NULL
WHERE ra_address_2 REGEXP '^[0-9]+$';


UPDATE silver_active_iowa_business
SET
    ra_city_altered = TRUE,
    ra_city_corrected = NULL
WHERE ra_city REGEXP '^[0-9]+$'
AND ra_zip IS NOT NULL;


UPDATE silver_active_iowa_business
SET
    ra_city_altered = TRUE,
    ra_city_corrected = NULL,
    ra_zip_altered = TRUE,
    ra_zip_corrected = ra_city
WHERE ra_city REGEXP '^[0-9]+$'
AND ra_zip IS NULL;


UPDATE silver_active_iowa_business
SET
    ra_state_altered = TRUE,
    ra_state_corrected = NULL,
    ra_city_altered = TRUE,
    ra_city_corrected = ra_state
WHERE ra_state REGEXP '^[A-Za-z]{3,}$'
AND ra_city IS NULL;


UPDATE silver_active_iowa_business
SET
    ra_city_altered = TRUE,
    ra_city_corrected =
        CASE ra_city
            WHEN 'CL' THEN 'CLIVE'
            WHEN 'DA' THEN 'DAVENPORT'
            WHEN 'LE' THEN 'LENOX'
            ELSE ra_city
        END
WHERE ra_city IN ('CL','DA','LE');


UPDATE silver_active_iowa_business
SET
    home_office_altered = TRUE,
    home_office_corrected = NULL,
    ho_zip_altered = TRUE,
    ho_zip_corrected = home_office,
    ho_country_altered = TRUE,
    ho_country_corrected = NULL
WHERE home_office REGEXP '^[0-9]+$';


UPDATE silver_active_iowa_business
SET
    ho_address_1_altered = TRUE,
    ho_address_1_corrected = NULL
WHERE ho_address_1 REGEXP '^[0-9]+$';


UPDATE silver_active_iowa_business
SET
    ho_address_2_altered = TRUE,
    ho_address_2_corrected = NULL
WHERE ho_address_2 REGEXP '^[0-9]+$';


UPDATE silver_active_iowa_business
SET
    ho_city_altered = TRUE,
    ho_city_corrected = NULL
WHERE ho_city REGEXP '^[0-9]+$'
AND ho_zip IS NOT NULL;


UPDATE silver_active_iowa_business
SET
    ho_city_altered = TRUE,
    ho_city_corrected = NULL,
    ho_zip_altered = TRUE,
    ho_zip_corrected = ho_city
WHERE ho_city REGEXP '^[0-9]+$'
AND ho_zip IS NULL;


UPDATE silver_active_iowa_business
SET
    ho_country_altered = TRUE,
    ho_country_corrected = NULL,
    ho_zip_altered = TRUE,
    ho_zip_corrected = ho_country
WHERE ho_country REGEXP '^[0-9]+$';


UPDATE silver_active_iowa_business
SET
    ho_state_altered = TRUE,
    ho_state_corrected = NULL,
    ho_city_altered = TRUE,
    ho_city_corrected = ho_state
WHERE ho_state REGEXP '^[A-Za-z]{3,}$'
AND ho_city IS NULL;


UPDATE silver_active_iowa_business
SET
    ho_city_altered = TRUE,
    ho_city_corrected =
        CASE ho_city
            WHEN 'DM' THEN 'DES MOINES'
            WHEN 'CH' THEN 'CEDAR FALLS'
            WHEN 'WE' THEN 'WEST DES MOINES'
            WHEN 'MO' THEN 'MOUNT PLEASANT'
            WHEN 'NE' THEN 'NEWTON'
            WHEN 'OP' THEN 'ORANGE CITY'
            WHEN 'TA' THEN 'TAMA'
            WHEN 'UP' THEN 'UNION PARK'
            WHEN 'NY' THEN 'NEW YORK'
            ELSE ho_city
        END
WHERE ho_city IN ('DM','CH','WE','MO','NE','OP','TA','UP','NY');

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