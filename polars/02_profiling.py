import os
import polars as pl

raw_data_path = "data/raw/diabetic_data.csv"

def profile_data():
    if not os.path.exists(raw_data_path):
        print(f"⚠️ Raw data file not found at '{raw_data_path}' to profile.")
        return

    df = pl.read_csv(raw_data_path, null_values=["?"])
    
    print("=== General Dataset Profile ===")
    print(f"Total Rows: {df.height}")
    print(f"Total Columns: {df.width}")
    
    print("\n=== Missing Values Summary (Top Columns) ===")
    null_counts = df.null_count()
    null_pct = [(col, null_counts[col][0], round(100 * null_counts[col][0] / df.height, 2)) for col in df.columns]
    null_pct = sorted(null_pct, key=lambda x: x[1], reverse=True)
    for col, count, pct in null_pct[:10]:
        if count > 0:
            print(f" - {col}: {count} nulls ({pct}%)")

    print("\n=== Age Group Distribution ===")
    print(df["age"].value_counts().sort("age"))

    print("\n=== Target Variable ('readmitted') Distribution ===")
    print(df["readmitted"].value_counts())

    print("\n=== Numeric Columns Descriptives ===")
    numeric_cols = [col for col, dtype in zip(df.columns, df.dtypes) if dtype in [pl.Int64, pl.Float64]]
    if numeric_cols:
        print(df.select(numeric_cols).describe())

if __name__ == "__main__":
    profile_data()
