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
    ra_corrected = TRUE,
    ra_address_1_corrected = NULL
WHERE ra_address_1 REGEXP '^[0-9]+$';