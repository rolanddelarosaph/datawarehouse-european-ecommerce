import sys
import time
import logging
from pathlib import Path

# ── Resolve project root so `src` is importable from anywhere ─────────────────
PROJECT_ROOT = Path(__file__).resolve().parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.pipeline import run_pipeline

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(PROJECT_ROOT / "pipeline.log", encoding="utf-8"),
    ],
)

if __name__ == "__main__":
    start = time.perf_counter()
    try:
        run_pipeline()
        elapsed = time.perf_counter() - start
        logging.info(f"Total elapsed time: {elapsed:.2f}s")
        sys.exit(0)
    except Exception:
        sys.exit(1)

