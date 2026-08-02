import os
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

user = os.getenv("MYSQL_USER")
password = os.getenv("MYSQL_PASSWORD")
host = os.getenv("MYSQL_HOST")
port = os.getenv("MYSQL_PORT")
database = os.getenv("MYSQL_DATABASE")

engine = create_engine(f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}")


def test_bronze_has_rows():
    df = pd.read_sql("SELECT COUNT(*) AS n FROM bronze_active_iowa_business", con=engine)
    assert df["n"][0] > 0


def test_silver_row_count_matches_bronze():
    bronze_count = pd.read_sql("SELECT COUNT(*) AS n FROM bronze_active_iowa_business", con=engine)["n"][0]
    silver_count = pd.read_sql("SELECT COUNT(*) AS n FROM silver_active_iowa_business", con=engine)["n"][0]
    assert silver_count == bronze_count


def test_silver_corp_number_unique():
    df = pd.read_sql(
        """
        SELECT corp_number, COUNT(*) AS n
        FROM silver_active_iowa_business
        GROUP BY corp_number
        HAVING COUNT(*) > 1
        """,
        con=engine
    )
    assert len(df) == 0


def test_gold_fact_corp_number_unique():
    df = pd.read_sql(
        """
        SELECT corp_number, COUNT(*) AS n
        FROM gold_fact_active_business
        GROUP BY corp_number
        HAVING COUNT(*) > 1
        """,
        con=engine
    )
    assert len(df) == 0


def test_gold_fact_row_count_matches_silver():
    silver_count = pd.read_sql("SELECT COUNT(*) AS n FROM silver_active_iowa_business", con=engine)["n"][0]
    fact_count = pd.read_sql("SELECT COUNT(*) AS n FROM gold_fact_active_business", con=engine)["n"][0]
    assert fact_count == silver_count


def test_no_orphaned_date_keys():
    df = pd.read_sql(
        """
        SELECT f.corp_number
        FROM gold_fact_active_business AS f
        LEFT JOIN gold_dim_date AS d ON f.date_key = d.date_key
        WHERE f.date_key IS NOT NULL AND d.date_key IS NULL
        """,
        con=engine
    )
    assert len(df) == 0


def test_no_orphaned_corporation_type_keys():
    df = pd.read_sql(
        """
        SELECT f.corp_number
        FROM gold_fact_active_business AS f
        LEFT JOIN gold_dim_corporation_type AS ct ON f.corporation_type_key = ct.corporation_type_key
        WHERE f.corporation_type_key IS NOT NULL AND ct.corporation_type_key IS NULL
        """,
        con=engine
    )
    assert len(df) == 0


def test_no_orphaned_ra_location_keys():
    df = pd.read_sql(
        """
        SELECT f.corp_number
        FROM gold_fact_active_business AS f
        LEFT JOIN gold_dim_ra_location AS ra ON f.ra_location_key = ra.ra_location_key
        WHERE f.ra_location_key IS NOT NULL AND ra.ra_location_key IS NULL
        """,
        con=engine
    )
    assert len(df) == 0


def test_no_orphaned_ho_location_keys():
    df = pd.read_sql(
        """
        SELECT f.corp_number
        FROM gold_fact_active_business AS f
        LEFT JOIN gold_dim_ho_location AS ho ON f.ho_location_key = ho.ho_location_key
        WHERE f.ho_location_key IS NOT NULL AND ho.ho_location_key IS NULL
        """,
        con=engine
    )
    assert len(df) == 0


def test_dates_within_sane_range():
    df = pd.read_sql("SELECT full_date FROM gold_dim_date WHERE full_date IS NOT NULL", con=engine)
    dates = pd.to_datetime(df["full_date"])
    assert (dates >= pd.Timestamp("1800-01-01")).all()
    assert (dates <= pd.Timestamp("2027-12-31")).all()


def test_no_leftover_numeric_junk_in_corrected_fields():
    fields = [
        "ra_address_1_corrected", "ra_address_2_corrected", "ra_city_corrected",
        "home_office_corrected", "ho_address_1_corrected", "ho_address_2_corrected",
        "ho_city_corrected",
    ]
    for field in fields:
        df = pd.read_sql(
            f"SELECT corp_number FROM silver_active_iowa_business WHERE {field} REGEXP '^[0-9]+$'",
            con=engine
        )
        assert len(df) == 0, f"{field} still has {len(df)} rows with numeric-only junk"


def test_view_row_count_matches_fact():
    fact_count = pd.read_sql("SELECT COUNT(*) AS n FROM gold_fact_active_business", con=engine)["n"][0]
    view_count = pd.read_sql("SELECT COUNT(*) AS n FROM gold_active_iowa_business", con=engine)["n"][0]
    assert view_count == fact_count