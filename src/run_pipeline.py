# run_pipeline.py
import logging
import os
import sys
from pathlib import Path

from sqlalchemy import create_engine, text

SRC_DIR = Path(__file__).parent / "src"
LOG_FILE = Path(__file__).parent / "pipeline.log"

# pipeline order matters, bronze must load before silver, silver before gold
# silver_clean.sql is superseded by silver_clean_update.sql, which is self-contained
PIPELINE_FILES = [
    "bronze_load.sql",
    "silver_clean_update.sql",
    "gold_schema.sql",
]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


def get_engine():
    user = os.environ["DB_USER"]
    password = os.environ["DB_PASSWORD"]
    host = os.environ["DB_HOST"]
    database = os.environ["DB_NAME"]
    url = f"mysql+mysqlconnector://{user}:{password}@{host}/{database}"
    return create_engine(url)


def run_sql_file(connection, filepath: Path):
    logger.info(f"running {filepath.name}...")
    sql = filepath.read_text()

    # split on ';' to run one statement at a time, skip empty fragments
    statements = [s.strip() for s in sql.split(";") if s.strip()]

    for i, statement in enumerate(statements, start=1):
        try:
            connection.execute(text(statement))
        except Exception as e:
            logger.error(f"{filepath.name}: statement {i} of {len(statements)} failed: {e}")
            raise

    logger.info(f"done: {filepath.name} ({len(statements)} statements)")


def main():
    logger.info("pipeline started")
    engine = get_engine()

    with engine.begin() as connection:
        try:
            for filename in PIPELINE_FILES:
                filepath = SRC_DIR / filename
                if not filepath.exists():
                    raise FileNotFoundError(f"missing pipeline file: {filepath}")
                run_sql_file(connection, filepath)

            logger.info("pipeline complete, all changes committed")

        except Exception as e:
            logger.error(f"pipeline failed, rolled back: {e}")
            raise


if __name__ == "__main__":
    main()