import os
import polars as pl
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DB_URL = os.getenv("DATABASE_URL")
RAW_DATA_PATH = "data/raw/diabetic_data.csv"
RAW_TABLE = "staging.raw_diabetic_data"  # full 50-column mirror of the CSV


def load_data() -> pl.DataFrame | None:
    """Read the raw CSV into a Polars DataFrame (treating '?' as null)."""
    if not os.path.exists(RAW_DATA_PATH):
        print(
            f"\u26a0\ufe0f Raw data file not found at '{RAW_DATA_PATH}'. "
            "Please download and place diabetic_data.csv there."
        )
        return None

    print(f"Reading raw patient data from {RAW_DATA_PATH} using Polars...")
    df = pl.read_csv(RAW_DATA_PATH, null_values=["?"])
    print(f"Data successfully loaded. Shape: {df.shape}")
    return df


def stage_to_database(df: pl.DataFrame) -> None:
    """Upload the full raw DataFrame to a staging table in Neon (ADRESS engine).

    Note: this mirrors the CSV's full 50-column schema into `staging.raw_diabetic_data`.
    The narrower, typed `staging.raw_clinical_records` table used by the SQL pipeline
    is populated by `sql/01_staging.sql` from `public.diabetic_data`.
    """
    if not DB_URL:
        print(
            "\u26a0\ufe0f DATABASE_URL not set (.env missing?). "
            "Skipping database upload; returning in-memory DataFrame only."
        )
        return

    print(f"Connecting to database and uploading to {RAW_TABLE}...")
    try:
        df.write_database(
            table_name=RAW_TABLE,
            connection=DB_URL,
            engine="adbc",
            if_table_exists="replace",
        )
        print(f"\u2705 Uploaded {df.shape[0]} rows to {RAW_TABLE}.")
    except Exception as e:
        print(
            f"\u274c Error uploading to database: {e}\n"
            "The in-memory DataFrame is still returned so downstream steps can continue."
        )


if __name__ == "__main__":
    df = load_data()
    if df is not None:
        stage_to_database(df)