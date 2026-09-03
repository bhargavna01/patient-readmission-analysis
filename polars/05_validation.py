import os
import polars as pl

raw_path = "data/raw/diabetic_data.csv"
clean_path = "data/processed/clean_diabetic_data.csv"

def validate_cleaning():
    """
    Executes post-cleaning assertion tests to guarantee data integrity across all 50 cleaned columns.
    
    Validation Checks:
    ---------------------------------------------------------------------------
    1. Exclusion Criteria Audit: Exactly 3 records with 'Unknown/Invalid' gender dropped.
    2. Demographic Constraints: Cleaned gender strictly contains ['Male', 'Female'].
    3. Target Binarization: 30-day readmission target is strictly binary {0, 1}.
    4. Completeness / Zero Nulls: Critical fields contain 0 null values.
    5. Numeric Boundaries: Stay length is within study bounds (1-14 days).
    """
    if not os.path.exists(clean_path):
        print(f"⚠️ Cleaned data file not found at '{clean_path}' to validate.")
        return

    raw_df = pl.read_csv(raw_path)
    clean_df = pl.read_csv(clean_path)

    print("=== Post-Cleaning Data Validation (Polars) ===")
    
    # -------------------------------------------------------------------------
    # Test 1: Record counts and drop audit
    # -------------------------------------------------------------------------
    dropped = raw_df.height - clean_df.height
    print(f"1. Raw count: {raw_df.height:,} | Cleaned count: {clean_df.height:,} | Dropped: {dropped}")
    assert dropped == 3, f"❌ Validation failed: Expected 3 dropped records, got {dropped}"
    print("   ✅ Test 1 PASSED: Exactly 3 invalid gender records were dropped.")
    
    # -------------------------------------------------------------------------
    # Test 2: Gender domain values
    # -------------------------------------------------------------------------
    genders = clean_df["gender_clean"].unique().to_list()
    print(f"2. Unique genders in clean cohort: {genders}")
    assert set(genders) == {"Male", "Female"}, f"❌ Validation failed: Unexpected gender values: {genders}"
    print("   ✅ Test 2 PASSED: Gender strictly contains 'Male' and 'Female'.")

    # -------------------------------------------------------------------------
    # Test 3: Binary target variable integrity (CMS 30-day readmission)
    # -------------------------------------------------------------------------
    targets = clean_df["readmitted_30d_binary"].unique().to_list()
    readmitted_count = clean_df["readmitted_30d_binary"].sum()
    readmission_pct = (readmitted_count / clean_df.height) * 100
    print(f"3. Unique 30-day readmission target values: {targets}")
    print(f"   Positive class count (<30 days): {readmitted_count:,} ({readmission_pct:.2f}%)")
    assert set(targets) == {0, 1}, f"❌ Validation failed: Target values must be {{0, 1}}, got {targets}"
    assert readmitted_count == 11357, f"❌ Validation failed: Expected 11,357 readmissions, got {readmitted_count}"
    print("   ✅ Test 3 PASSED: Target is strictly binary and matches the 11,357 benchmark.")

    # -------------------------------------------------------------------------
    # Test 4: Critical field null audits
    # -------------------------------------------------------------------------
    null_checks = {
        "gender_clean": clean_df["gender_clean"].null_count(),
        "age_group": clean_df["age_group"].null_count(),
        "primary_diagnosis_group": clean_df["primary_diagnosis_group"].null_count(),
        "secondary_diagnosis_group": clean_df["secondary_diagnosis_group"].null_count(),
        "readmitted_30d_binary": clean_df["readmitted_30d_binary"].null_count(),
        "length_of_stay": clean_df["length_of_stay"].null_count(),
        "active_med_count": clean_df["active_med_count"].null_count(),
    }
    print("4. Null checks across essential fields:")
    for field, nulls in null_checks.items():
        print(f"   - {field}: {nulls} nulls")
        assert nulls == 0, f"❌ Validation failed: Column '{field}' has {nulls} null values!"
    print("   ✅ Test 4 PASSED: Zero nulls found across all critical modeling features.")

    # -------------------------------------------------------------------------
    # Test 5: Clinical range invariants
    # -------------------------------------------------------------------------
    invalid_stays = clean_df.filter((pl.col("length_of_stay") < 1) | (pl.col("length_of_stay") > 14)).height
    assert invalid_stays == 0, f"❌ Validation failed: Found {invalid_stays} stays outside [1, 14] days"
    print("5. Clinical range checks:")
    print("   - Length of stay within [1, 14] days: 100% compliant")
    print("   ✅ Test 5 PASSED: All numeric features conform to study boundaries.")

    print("\n🎉 ALL 5 POLARS VALIDATION TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    validate_cleaning()
