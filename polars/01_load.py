import os
import polars as pl
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

db_url = os.getenv("DATABASE_URL")
raw_data_path = "data/raw/diabetic_data.csv"

def load_data():
    if not os.path.exists(raw_data_path):
        print(f"⚠️ Raw data file not found at '{raw_data_path}'. Please download and place the diabetic_data.csv file there.")
        return None

    print(f"Reading raw patient data from {raw_data_path} using Polars...")
    # Read CSV, treating '?' as null values
    df = pl.read_csv(raw_data_path, null_values=["?"])
    print(f"Data successfully loaded. Shape: {df.shape}")
    
    if db_url:
        print(f"Connecting to database and uploading raw data to staging.raw_clinical_records...")
        try:
            # We map target fields to match the database raw encounter structure if needed
            # In a real environment, we'd write to the db:
            # df.write_database(
            #     table_name="staging.raw_clinical_records",
            #     connection=db_url,
            #     engine="adbc",
            #     if_table_exists="replace"
            # )
            print("✅ Data write simulation completed successfully (uncomment write_database in production).")
        except Exception as e:
            print(f"❌ Error uploading to database: {e}")
            
    return df

if __name__ == "__main__":
    load_data()
