import os
import polars as pl

raw_data_path = "data/raw/diabetic_data.csv"

def run_quality_checks():
    if not os.path.exists(raw_data_path):
        print(f"⚠️ Raw data file not found at '{raw_data_path}' to perform quality checks.")
        return

    df = pl.read_csv(raw_data_path, null_values=["?"])

    # 1. Duplicates check
    dup_count = df.height - df["encounter_id"].n_unique()
    print(f"1. Duplicate encounters: {dup_count} (Expected: 0)")

    # 2. Stay length check (Inclusion criteria: stay 1-14 days)
    invalid_stays = df.filter((pl.col("time_in_hospital") < 1) | (pl.col("time_in_hospital") > 14)).height
    print(f"2. Records with invalid length of stay (<1 or >14 days): {invalid_stays}")

    # 3. Missing identifiers
    missing_ids = df.filter(pl.col("encounter_id").is_null() | pl.col("patient_nbr").is_null()).height
    print(f"3. Records with missing encounter_id or patient_nbr: {missing_ids}")

    # 4. Gender check
    invalid_genders = df.filter(pl.col("gender").is_in(["Unknown/Invalid", "Unknown"]) | pl.col("gender").is_null()).height
    print(f"4. Records with invalid/unknown gender: {invalid_genders}")

if __name__ == "__main__":
    run_quality_checks()
