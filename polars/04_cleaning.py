import os
import polars as pl

raw_data_path = "data/raw/diabetic_data.csv"
output_path = "data/processed/clean_diabetic_data.csv"

def clean_diagnosis_group(col_name):
    # Standardize string codes to int for comparison
    # ICD-9 group check helper using regex and casting
    return (
        pl.when(pl.col(col_name).is_null() | (pl.col(col_name) == "?"))
        .then(pl.lit("Unknown"))
        .when(pl.col(col_name).str.starts_with("250"))
        .then(pl.lit("Diabetes"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (
                pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(390, 459) |
                (pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False) == 785)
            )
        )
        .then(pl.lit("Circulatory"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (
                pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(460, 519) |
                (pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False) == 786)
            )
        )
        .then(pl.lit("Respiratory"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (
                pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(520, 579) |
                (pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False) == 787)
            )
        )
        .then(pl.lit("Digestive"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            (
                pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(580, 629) |
                (pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False) == 788)
            )
        )
        .then(pl.lit("Genitourinary"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(140, 239)
        )
        .then(pl.lit("Neoplasms"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(710, 739)
        )
        .then(pl.lit("Musculoskeletal"))
        .when(
            pl.col(col_name).str.contains(r"^[0-9]") & 
            pl.col(col_name).str.split(".").list.get(0).cast(pl.Int32, strict=False).is_between(800, 999)
        )
        .then(pl.lit("Injury"))
        .otherwise(pl.lit("Other"))
    )

def clean_data():
    if not os.path.exists(raw_data_path):
        print(f"⚠️ Raw data file not found at '{raw_data_path}' to perform cleaning.")
        return None

    df = pl.read_csv(raw_data_path, null_values=["?"])

    # Perform cleaning
    cleaned_df = (
        df.filter(
            pl.col("patient_nbr").is_not_null() &
            (~pl.col("gender").is_in(["Unknown/Invalid", "Unknown"]))
        )
        .with_columns([
            # Standardize Gender
            pl.col("gender").str.to_titlecase().alias("gender_clean"),
            
            # Map Readmission Target
            pl.when(pl.col("readmitted") == "<30").then(1).otherwise(0).alias("readmitted_binary"),
            
            # Fill missing numerical variables
            pl.col("time_in_hospital").fill_null(0),
            pl.col("num_lab_procedures").fill_null(0),
            pl.col("num_medications").fill_null(0),
            pl.col("number_emergency").fill_null(0),
            pl.col("number_inpatient").fill_null(0),
            
            # Diagnose Classifications
            clean_diagnosis_group("diag_1").alias("primary_diagnosis_group")
        ])
    )

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    cleaned_df.write_csv(output_path)
    print(f"✅ Data cleaning successful. Output written to '{output_path}'. Shape: {cleaned_df.shape}")
    return cleaned_df

if __name__ == "__main__":
    clean_data()
