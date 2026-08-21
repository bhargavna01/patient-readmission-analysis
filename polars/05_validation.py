import os
import polars as pl

raw_path = "data/raw/diabetic_data.csv"
clean_path = "data/processed/clean_diabetic_data.csv"

def validate_cleaning():
    if not os.path.exists(clean_path):
        print(f"⚠️ Cleaned data file not found at '{clean_path}' to validate.")
        return

    raw_df = pl.read_csv(raw_path, null_values=["?"])
    clean_df = pl.read_csv(clean_path)

    print("=== Post-Cleaning Validation ===")
    
    # 1. Row counts validation
    print(f"1. Raw count: {raw_df.height} | Cleaned count: {clean_df.height}")
    diff = raw_df.height - clean_df.height
    print(f"   Dropped rows: {diff}")
    
    # 2. Gender values validation
    genders = clean_df["gender_clean"].unique().to_list()
    print(f"2. Unique genders in clean data: {genders} (Expected no 'Unknown/Invalid')")
    assert "Unknown/Invalid" not in genders, "❌ Validation failed: Invalid genders found!"

    # 3. Binary target variable validation
    targets = clean_df["readmitted_binary"].unique().to_list()
    print(f"3. Unique target values: {targets} (Expected [0, 1] or a subset)")
    assert all(t in [0, 1] for t in targets), "❌ Validation failed: Target variable contains non-binary values!"

    # 4. Check for unexpected nulls
    null_genders = clean_df["gender_clean"].null_count()
    null_diags = clean_df["primary_diagnosis_group"].null_count()
    print(f"4. Null genders: {null_genders} | Null primary diagnosis groups: {null_diags}")
    assert null_genders == 0, "❌ Validation failed: Cleaned gender column contains nulls!"
    assert null_diags == 0, "❌ Validation failed: Cleaned diagnosis groups column contains nulls!"

    print("✅ All validation checks passed successfully!")

if __name__ == "__main__":
    validate_cleaning()
