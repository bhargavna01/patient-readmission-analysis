import os
import polars as pl

raw_data_path = "data/raw/diabetic_data.csv"
output_path = "data/processed/clean_diabetic_data.csv"

def classify_icd9_diagnosis(col_name: str) -> pl.Expr:
    """
    Classifies raw ICD-9 alphanumeric diagnosis codes into 9 clinical taxonomy groups.
    
    Clinical & HL7 Rationale:
    - 250.xx codes represent Diabetes mellitus.
    - 390-459 and 785 represent Circulatory system conditions (hypertension, heart failure).
    - 460-519 and 786 represent Respiratory conditions (pneumonia, COPD).
    - 520-579 and 787 represent Digestive disorders.
    - 580-629 and 788 represent Genitourinary conditions (kidney disease).
    - 140-239 represent Neoplasms/malignancies.
    - 710-739 represent Musculoskeletal system conditions.
    - 800-999 represent Injuries and poisoning.
    - All other values are classified as 'Other'.
    """
    prefix_int = pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False)
    
    return (
        pl.when(pl.col(col_name).is_null() | (pl.col(col_name) == "?"))
        .then(pl.lit("Unknown"))
        .when(pl.col(col_name).str.starts_with("250"))
        .then(pl.lit("Diabetes"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (prefix_int.is_between(390, 459) | (prefix_int == 785))
        )
        .then(pl.lit("Circulatory"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (prefix_int.is_between(460, 519) | (prefix_int == 786))
        )
        .then(pl.lit("Respiratory"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (prefix_int.is_between(520, 579) | (prefix_int == 787))
        )
        .then(pl.lit("Digestive"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (prefix_int.is_between(580, 629) | (prefix_int == 788))
        )
        .then(pl.lit("Genitourinary"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            prefix_int.is_between(140, 239)
        )
        .then(pl.lit("Neoplasms"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            prefix_int.is_between(710, 739)
        )
        .then(pl.lit("Musculoskeletal"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            prefix_int.is_between(800, 999)
        )
        .then(pl.lit("Injury"))
        .otherwise(pl.lit("Other"))
    )

def clean_data():
    """
    Executes an end-to-end data cleaning and transformation pipeline across ALL 50 columns
    using the high-performance, multi-threaded Polars expression framework.
    """
    if not os.path.exists(raw_data_path):
        print(f"⚠️ Raw data file not found at '{raw_data_path}' to perform cleaning.")
        return None

    # Ingest raw CSV data
    df = pl.read_csv(raw_data_path)
    print(f"Loaded raw dataset with {df.height} rows and {df.width} columns.")

    # Define the 24 diabetes medication columns
    med_cols = [
        "metformin", "repaglinide", "nateglinide", "chlorpropamide",
        "glimepiride", "acetohexamide", "glipizide", "glyburide",
        "tolbutamide", "pioglitazone", "rosiglitazone", "acarbose",
        "miglitol", "troglitazone", "tolazamide", "examide",
        "citoglipton", "insulin", "glyburide-metformin", "glipizide-metformin",
        "glimepiride-pioglitazone", "metformin-rosiglitazone", "metformin-pioglitazone"
    ]

    # Build active medication count expression (number of medications where value != 'No' and != '?')
    active_med_expr = pl.sum_horizontal([
        pl.when(~pl.col(med).is_in(["No", "?", "None", ""])).then(1).otherwise(0)
        for med in med_cols
    ]).alias("active_med_count")

    # Clean and standardize all 50 columns
    cleaned_df = (
        df
        # 1. Filter: Exclude the 3 invalid gender records to enforce demographic consistency
        .filter(
            pl.col("patient_nbr").is_not_null() &
            (~pl.col("gender").is_in(["Unknown/Invalid", "Unknown"]))
        )
        .with_columns([
            # 2. Identifiers
            pl.col("encounter_id").cast(pl.Int64),
            pl.col("patient_nbr").cast(pl.Int64).alias("patient_id"),

            # 3. Demographics
            pl.when(pl.col("race").is_in(["?", "None", ""])).then(pl.lit("Unknown")).otherwise(pl.col("race")).alias("race_clean"),
            pl.col("gender").str.to_titlecase().alias("gender_clean"),
            pl.when(pl.col("age").is_in(["?", "None", ""])).then(pl.lit("Unknown")).otherwise(pl.col("age")).alias("age_group"),
            pl.when(pl.col("weight").is_in(["?", "None", ""])).then(pl.lit("Missing")).otherwise(pl.col("weight")).alias("weight_clean"),

            # 4. Admission & Discharge Descriptions
            pl.col("admission_type_id").cast(pl.Int32, strict=False),
            pl.when(pl.col("admission_type_id").is_in([1, 7])).then(pl.lit("Emergency"))
              .when(pl.col("admission_type_id") == 2).then(pl.lit("Urgent"))
              .when(pl.col("admission_type_id") == 3).then(pl.lit("Elective"))
              .when(pl.col("admission_type_id") == 4).then(pl.lit("Newborn"))
              .otherwise(pl.lit("Other/Unknown")).alias("admission_type_desc"),

            pl.col("discharge_disposition_id").cast(pl.Int32, strict=False),
            pl.when(pl.col("discharge_disposition_id") == 1).then(pl.lit("Discharged to Home"))
              .when(pl.col("discharge_disposition_id").is_in([11, 13, 14, 19, 20, 21])).then(pl.lit("Expired/Hospice"))
              .when(pl.col("discharge_disposition_id").is_in([2, 3, 4, 5, 22, 23, 24])).then(pl.lit("Transferred Facility"))
              .when(pl.col("discharge_disposition_id").is_in([6, 8])).then(pl.lit("Home Health Service"))
              .otherwise(pl.lit("Other/Unknown")).alias("discharge_disposition_desc"),

            pl.col("admission_source_id").cast(pl.Int32, strict=False),
            pl.when(pl.col("admission_source_id") == 7).then(pl.lit("Emergency Room"))
              .when(pl.col("admission_source_id").is_in([1, 2])).then(pl.lit("Physician/Clinic Referral"))
              .when(pl.col("admission_source_id").is_in([4, 5, 6])).then(pl.lit("Transfer from Hospital/Facility"))
              .otherwise(pl.lit("Other Referral")).alias("admission_source_desc"),

            # 5. Length of Stay & Utilization Metrics
            pl.col("time_in_hospital").cast(pl.Int32, strict=False).fill_null(0).alias("length_of_stay"),
            pl.col("num_lab_procedures").cast(pl.Int32, strict=False).fill_null(0),
            pl.col("num_procedures").cast(pl.Int32, strict=False).fill_null(0),
            pl.col("num_medications").cast(pl.Int32, strict=False).fill_null(0),
            pl.col("number_outpatient").cast(pl.Int32, strict=False).fill_null(0),
            pl.col("number_emergency").cast(pl.Int32, strict=False).fill_null(0),
            pl.col("number_inpatient").cast(pl.Int32, strict=False).fill_null(0),
            pl.col("number_diagnoses").cast(pl.Int32, strict=False).fill_null(0),

            # Composite prior utilization metric
            (
                pl.col("number_outpatient").cast(pl.Int32, strict=False).fill_null(0) +
                pl.col("number_emergency").cast(pl.Int32, strict=False).fill_null(0) +
                pl.col("number_inpatient").cast(pl.Int32, strict=False).fill_null(0)
            ).alias("total_prior_visits"),

            # 6. Administrative & Physician Specialty
            pl.when(pl.col("payer_code").is_in(["?", "None", ""])).then(pl.lit("Unknown/Uninsured")).otherwise(pl.col("payer_code")).alias("payer_code_clean"),
            pl.when(pl.col("medical_specialty").is_in(["?", "None", ""])).then(pl.lit("Missing"))
              .when(pl.col("medical_specialty").str.contains("Cardiology")).then(pl.lit("Cardiology"))
              .when(pl.col("medical_specialty").str.contains("Surgery")).then(pl.lit("Surgery"))
              .when(pl.col("medical_specialty").str.contains("InternalMedicine")).then(pl.lit("Internal Medicine"))
              .when(pl.col("medical_specialty").str.contains("Family|General")).then(pl.lit("General/Family Practice"))
              .when(pl.col("medical_specialty").str.contains("Emergency")).then(pl.lit("Emergency Medicine"))
              .otherwise(pl.lit("Other Specialty")).alias("medical_specialty_clean"),

            # 7. Diagnoses & ICD-9 Groupings
            classify_icd9_diagnosis("diag_1").alias("primary_diagnosis_group"),
            classify_icd9_diagnosis("diag_2").alias("secondary_diagnosis_group"),
            classify_icd9_diagnosis("diag_3").alias("tertiary_diagnosis_group"),

            # 8. Laboratory Glycemic Tests
            pl.when(pl.col("max_glu_serum").is_in(["None", "?", ""])).then(pl.lit("Not Tested")).otherwise(pl.col("max_glu_serum")).alias("max_glu_serum_clean"),
            pl.when(pl.col("A1Cresult").is_in(["None", "?", ""])).then(pl.lit("Not Tested")).otherwise(pl.col("A1Cresult")).alias("a1c_result_clean"),

            # 9. Active Medication Count
            active_med_expr,

            # 10. Medication Changes
            pl.when(pl.col("change") == "Ch").then(pl.lit("Change")).otherwise(pl.lit("No Change")).alias("med_change"),
            pl.when(pl.col("diabetesMed").str.to_uppercase() == "YES").then(pl.lit("Yes")).otherwise(pl.lit("No")).alias("diabetes_med_prescribed"),

            # 11. Target Variables
            pl.col("readmitted").alias("readmitted_raw"),
            pl.when(pl.col("readmitted") == "<30").then(1).otherwise(0).alias("readmitted_30d_binary"),
            pl.when(pl.col("readmitted").is_in(["<30", ">30"])).then(1).otherwise(0).alias("readmitted_any_binary")
        ])
    )

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    cleaned_df.write_csv(output_path)
    print(f"✅ Data cleaning successful. Output written to '{output_path}'. Shape: {cleaned_df.shape}")
    return cleaned_df

if __name__ == "__main__":
    clean_data()
