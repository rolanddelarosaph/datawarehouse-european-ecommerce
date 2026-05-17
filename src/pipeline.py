import logging
from pathlib import Path
from src.db import get_connection, execute_sql_file
from src.config import BASE_PATH, SQL_PATH

logger = logging.getLogger(__name__)

# ── Bronze dataset registry ───────────────────────────────────────────────────
BRONZE_DATASETS = [
    ("bronze_sales_items", BASE_PATH / "commerce"   / "sales_items.csv"),
    ("bronze_sales",       BASE_PATH / "commerce"   / "sales.csv"),
    ("bronze_products",    BASE_PATH / "commerce"   / "products.csv"),
    ("bronze_customers",   BASE_PATH / "commerce"   / "customers.csv"),
    ("bronze_stock",       BASE_PATH / "operations" / "stock.csv"),
    ("bronze_channels",    BASE_PATH / "operations" / "channels.csv"),
    ("bronze_campaigns",   BASE_PATH / "operations" / "campaigns.csv"),
]

LOAD_SQL = """
    LOAD DATA LOCAL INFILE '{filepath}'
    INTO TABLE {table}
    FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
    LINES TERMINATED BY '\\n'
    IGNORE 1 ROWS;
"""


def _load_bronze(cursor) -> None:
    """Bulk-load all raw CSV files into Bronze tables."""
    for table, path in BRONZE_DATASETS:
        if not path.exists():
            raise FileNotFoundError(f"CSV not found: {path}")
        logger.info(f"  → Loading {table} from {path.name}")
        cursor.execute(LOAD_SQL.format(filepath=path.as_posix(), table=table))


def run_pipeline() -> None:
    logger.info("═" * 55)
    logger.info("  PIPELINE STARTED")
    logger.info("═" * 55)

    # ── INIT: connect WITHOUT a database to create it first ──────────────────
    import mysql.connector
    from src.config import DB_CONFIG
    init_conn = mysql.connector.connect(
        host=DB_CONFIG["host"],
        user=DB_CONFIG["user"],
        password=DB_CONFIG["password"],
    )
    logger.info("[1/4] Initializing data warehouse")
    execute_sql_file(SQL_PATH / "initialize_datawarehouse.sql", init_conn)
    init_conn.commit()
    init_conn.close()

    # ── Now connect normally with the database ────────────────────────────────
    conn   = get_connection()
    cursor = conn.cursor()

    try:
        conn.start_transaction()

        # ── BRONZE ────────────────────────────────────────────────────────────
        logger.info("[2/4] Bronze layer")
        execute_sql_file(SQL_PATH / "bronze" / "ddl_bronze.sql",             conn)
        execute_sql_file(SQL_PATH / "bronze" / "bronze_reset_procedure.sql", conn)
        cursor.execute("CALL bronze_load_bronze();")
        logger.info("  → Bronze tables reset")
        _load_bronze(cursor)

        # ── SILVER ────────────────────────────────────────────────────────────
        logger.info("[3/4] Silver layer")
        execute_sql_file(SQL_PATH / "silver" / "ddl_silver.sql",       conn)
        execute_sql_file(SQL_PATH / "silver" / "transform_silver.sql", conn)
        cursor.execute("CALL transform_silver_layer();")
        logger.info("  → Silver transformation complete")

        # ── GOLD ──────────────────────────────────────────────────────────────
        logger.info("[4/4] Gold layer")
        execute_sql_file(SQL_PATH / "gold" / "ddl_gold.sql", conn)

        conn.commit()
        logger.info("═" * 55)
        logger.info("  PIPELINE COMPLETED SUCCESSFULLY ✓")
        logger.info("═" * 55)

    except Exception as e:
        conn.rollback()
        logger.error("Pipeline failed — transaction rolled back.")
        logger.exception(e)
        raise
    finally:
        cursor.close()
        conn.close()