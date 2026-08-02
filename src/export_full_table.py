import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

QUERY = """
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
"""

OUTPUT_PATH = "data/exports/active_iowa_businesses.csv"


def run():
    user = os.getenv("MYSQL_USER")
    password = os.getenv("MYSQL_PASSWORD")
    host = os.getenv("MYSQL_HOST")
    port = os.getenv("MYSQL_PORT")
    database = os.getenv("MYSQL_DATABASE")

    engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")

    print("Running full view query...")
    df = pd.read_sql(QUERY, con=engine)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)

    print(f"Exported {len(df):,} rows to {OUTPUT_PATH}")


if __name__ == "__main__":
    run()