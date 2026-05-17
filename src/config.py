from pathlib import Path
from dotenv import load_dotenv
import os

load_dotenv()

ROOT_DIR = Path(__file__).resolve().parent.parent

DB_CONFIG = {
    "host":               os.environ.get("MYSQL_HOST", "localhost"),
    "user":               os.environ.get("MYSQL_USER"),
    "password":           os.environ.get("MYSQL_PASSWORD"),
    "database":           os.environ.get("MYSQL_DATABASE", "datawarehouse"),
    "allow_local_infile": True,
}

BASE_PATH = ROOT_DIR / "data"
SQL_PATH  = ROOT_DIR / "sql"
