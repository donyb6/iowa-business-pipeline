import logging
import subprocess
import sys
from pathlib import Path

from sqlalchemy import create_engine, text
import os

from dotenv import load_dotenv

load_dotenv()

SRC_DIR = Path(__file__).parent
PROJECT_ROOT = SRC_DIR.parent
LOG_DIR = PROJECT_ROOT / "logs"
LOG_DIR.mkdir(exist_ok=True)
LOG_FILE = LOG_DIR / "pipeline.log"


PIPELINE_STEPS = [
    "extract.py",
    "load_raw.py",
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
    user = os.getenv("MYSQL_USER")
    password = os.getenv("MYSQL_PASSWORD")
    host = os.getenv("MYSQL_HOST")
    port = os.getenv("MYSQL_PORT")
    database = os.getenv("MYSQL_DATABASE")
    url = f"mysql+mysqlconnector://{user}:{password}@{host}:{port}/{database}"
    return create_engine(url)


def run_python_script(filepath: Path):
    logger.info(f"running {filepath.name}...")
    result = subprocess.run(
        [sys.executable, str(filepath)],
        capture_output=True,
        text=True,
    )

    if result.stdout:
        logger.info(f"{filepath.name} output:\n{result.stdout}")

    if result.returncode != 0:
        logger.error(f"{filepath.name} failed:\n{result.stderr}")
        raise RuntimeError(f"{filepath.name} exited with code {result.returncode}")

    logger.info(f"done: {filepath.name}")


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

    # python steps run first, before any DB connection is needed
    for filename in PIPELINE_STEPS:
        if filename.endswith(".py"):
            filepath = SRC_DIR / filename
            if not filepath.exists():
                raise FileNotFoundError(f"missing pipeline file: {filepath}")
            run_python_script(filepath)

    engine = get_engine()

    with engine.begin() as connection:
        try:
            for filename in PIPELINE_STEPS:
                if filename.endswith(".sql"):
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