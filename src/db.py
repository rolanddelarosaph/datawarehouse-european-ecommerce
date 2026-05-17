import re
import logging
from pathlib import Path
import mysql.connector
from mysql.connector import MySQLConnection, Error
from src.config import DB_CONFIG

logger = logging.getLogger(__name__)


def get_connection() -> MySQLConnection:
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        logger.debug("Database connection established.")
        return conn
    except Error as e:
        logger.critical(f"Cannot connect to database: {e}")
        raise


def _split_sql(sql: str) -> list[str]:
    """
    Split a SQL script into individual statements,
    correctly handling DELIMITER changes used in stored procedures.
    """
    statements = []
    delimiter = ";"
    current = ""

    for line in sql.splitlines():
        stripped = line.strip()

        # Handle DELIMITER changes
        if stripped.upper().startswith("DELIMITER"):
            parts = stripped.split()
            if len(parts) >= 2:
                delimiter = parts[1]
            continue

        current += line + "\n"

        if current.strip().endswith(delimiter):
            stmt = current.strip()
            if delimiter != ";":
                stmt = stmt[: -len(delimiter)].strip()
            if stmt:
                statements.append(stmt)
            current = ""

    if current.strip():
        statements.append(current.strip())

    return statements


def execute_sql_file(filepath: str | Path, conn: MySQLConnection | None = None) -> None:
    filepath = Path(filepath)
    if not filepath.exists():
        raise FileNotFoundError(f"SQL file not found: {filepath}")

    owns_conn = conn is None
    if owns_conn:
        conn = get_connection()

    cursor = conn.cursor()
    try:
        sql = filepath.read_text(encoding="utf-8")
        statements = _split_sql(sql)
        for stmt in statements:
            if stmt.strip():
                cursor.execute(stmt)
                try:
                    cursor.fetchall()
                except Exception:
                    pass
        if owns_conn:
            conn.commit()
        logger.debug(f"Executed: {filepath.name}")
    except Error as e:
        logger.error(f"Failed executing {filepath.name}: {e}")
        raise
    finally:
        cursor.close()
        if owns_conn:
            conn.close()


def execute_query(cursor, conn: MySQLConnection, query: str) -> None:
    cursor.execute(query)
    conn.commit()