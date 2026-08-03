# Active Iowa Businesses ELT Pipeline

An end-to-end ELT pipeline for Iowa's active business registry dataset, built with Python and MySQL following a bronze/silver/gold architecture.

## Source

Iowa Health Data Hub, Active Businesses dataset (`https://idh-be.iowa.gov/api/v1/datasets/554/rows.csv`), 344,321 rows, 23 columns.

## Tech stack

- Python (extraction, orchestration, testing)
- MySQL (storage and transformation)
- pandas, SQLAlchemy, requests, python-dotenv, pytest, logging

## Project structure

```

active_iowa_businesses/
├── config/
│ └── columns.yaml
├── data/
│ └── raw/
│ └── active_iowa_businesses.csv
├── logs/
│ └── pipeline.log
├── src/
│ ├── extract.py
│ ├── load_raw.py
│ ├── silver_clean_update.sql
│ ├── gold_schema.sql
│ ├── drop_gold_schema.sql
│ └── run_pipeline.py
├── tests/
│ └── test_data_quality.py
├── .env
├── requirements.txt
└── README.md

```

## Architecture

### Extract and load

`extract.py` downloads the source dataset (handling both plain and zipped CSV responses) and saves it to `data/raw/active_iowa_businesses.csv`. `load_raw.py` reads that CSV and writes it into `bronze_active_iowa_business` in MySQL.

### Bronze

`bronze_active_iowa_business` holds the raw dataset as loaded, no transformations applied.

### Silver

`silver_active_iowa_business` is the cleaned working table, built with `CREATE TABLE ... AS SELECT` from bronze. Cleaning is done entirely in SQL (`silver_clean_update.sql`) and follows one rule throughout: raw values are never overwritten. Every field with a data quality issue gets a `<field>_corrected` and `<field>_altered` column pair, so the original value stays visible for audit and every fix is traceable.

### Gold

Star schema (`gold_schema.sql`) built from `silver_active_iowa_business`, sourced from the `_corrected` columns only.

**Fact table:** `gold_fact_active_business` — grain is one row per `corp_number`.

**Dimensions:**
- `gold_dim_date` — one row per distinct `effective_date`, includes `is_future` (flags forward-dated filings, since incorporations can be filed ahead of their legal start date)
- `gold_dim_corporation_type`
- `gold_dim_ra_location` — registered agent address
- `gold_dim_ho_location` — home office address

`ra` and `ho` locations use separate dimension tables rather than one shared role-playing dimension, since the two address types rarely overlap (registered agents are typically law firms or filing services, home offices are the actual place of business).

**View:** `gold_active_iowa_business` — joins fact to all four dimensions for querying without repeating the join logic each time.

## Data quality issues found and how they were handled

General rule: if a value has a valid home elsewhere in the row, it's moved there in the `_corrected` column. If it's pure junk with no recoverable data, `_corrected` is set to `NULL`. The raw column is never touched.

| Field | Issue | Resolution |
|---|---|---|
| `effective_date` | Mixed date formats | Parsed to `DATE` type |
| `corporation_type`, `registered_agent`, `legal_name` | Leading/trailing whitespace, stray quote characters | Trimmed |
| `ra_address_1`, `ra_address_2` | Numeric-only entries, no valid home | Set to `NULL` |
| `ra_city` | Numeric entries duplicating `ra_zip` | Set to `NULL`; the one row with no `ra_zip` had its value moved there instead |
| `ra_city` | 2-letter abbreviations (`CL`, `DA`, `LE`, etc.) | Resolved via lookup against full city names |
| `ra_state` | City names instead of state codes | Moved to `ra_city_corrected`, `ra_state_corrected` set to `NULL` |
| `home_office` / `ho_country` | Same numeric value duplicated across both fields, `ho_zip` empty | Recognised as one issue, value moved to `ho_zip_corrected`, both source fields nulled |
| `ho_address_1`, `ho_address_2` | Numeric-only entries, no valid home | Set to `NULL` |
| `ho_city` | Numeric entries duplicating `ho_zip` | Set to `NULL`; the one row with no `ho_zip` (`50213`) had its value moved there instead |
| `ho_state` | City names instead of state codes | Moved to `ho_city_corrected`, `ho_state_corrected` set to `NULL` |
| `ho_city` | 2-letter abbreviations (`DM`, `CH`, `WE`, `MO`, `NE`, `OP`, `TA`, `UP`, `NY`) | Resolved via lookup against full city names |
| `ho_location`, `ra_location` | Redundant `POINT(...)` string, duplicate of lat/long columns | Converted to MySQL `POINT` type, then dropped in favour of separate `latitude`/`longitude` text columns |

## Known limitations

- **`ho_city = 'CH'`**: its `ho_address_2` was already nulled by an earlier blanket cleanup step (values outside the `SUITE 200`/`SUITE 400`/`4TH FLOOR` whitelist) before this issue was catalogued. The correct city name (`CEDAR FALLS`) was cross-referenced from `bronze_active_iowa_business` rather than recovered from silver directly.
- Zip codes with fewer than 5 digits (e.g. `5200` for a Dubuque business) are a genuine truncation at source, left as-is per the "no swapping/correcting beyond what's found" rule — flagged here for awareness, not fixed.

## Running the pipeline

1. Set up `.env` in the project root with `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_DATABASE`.
2. Install dependencies:
```bash
   pip install -r requirements.txt
```
3. Run from the project root:
```bash
   python src/run_pipeline.py
```

This runs, in order: `extract.py` → `load_raw.py` → `silver_clean_update.sql` → `gold_schema.sql`. Progress and errors are logged to both the console and `logs/pipeline.log`. SQL steps run inside a single transaction and roll back fully on failure.

## Testing

```bash
pytest tests/test_data_quality.py -v
```

Covers row count consistency across bronze/silver/gold, `corp_number` uniqueness, referential integrity across all four dimension joins, absence of leftover numeric junk in `_corrected` fields, and that the `gold_active_iowa_business` view matches the fact table row count.

## Rebuilding the gold schema

`drop_gold_schema.sql` removes the view and all fact/dimension tables (with `FOREIGN_KEY_CHECKS` disabled to avoid drop-order issues) so the gold layer can be rebuilt from scratch.
