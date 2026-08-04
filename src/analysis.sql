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

