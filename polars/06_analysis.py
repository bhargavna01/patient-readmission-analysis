import os
import polars as pl
import matplotlib.pyplot as plt
import seaborn as sns

clean_path = "data/processed/clean_diabetic_data.csv"
charts_dir = "charts"

def run_analysis():
    if not os.path.exists(clean_path):
        print(f"⚠️ Cleaned data file not found at '{clean_path}' to analyze.")
        return

    df = pl.read_csv(clean_path)
    os.makedirs(charts_dir, exist_ok=True)
    sns.set_theme(style="whitegrid")

    print("=== Final Polars Analytics ===")

    # 1. Overall Readmission Rate
    overall_rate = df["readmitted_binary"].mean() * 100
    print(f"1. Overall 30-Day Readmission Rate: {overall_rate:.2f}%")

    # 2. Readmission by Age Group
    print("\n2. Readmission Rate by Age Group:")
    age_analysis = (
        df.group_by("age")
        .agg(
            total_encounters=pl.count(),
            readmitted_count=pl.sum("readmitted_binary"),
            readmission_rate=pl.col("readmitted_binary").mean() * 100
        )
        .sort("age")
    )
    print(age_analysis)

    # Plot 1: Readmission by Age
    plt.figure(figsize=(8, 5))
    sns.barplot(
        x=age_analysis["age"].to_list(), 
        y=age_analysis["readmission_rate"].to_list(), 
        palette="viridis"
    )
    plt.title("Readmission Rate by Age Group (Polars)")
    plt.ylabel("Readmission Rate (%)")
    plt.xlabel("Age Group")
    plt.savefig(os.path.join(charts_dir, "readmission_by_age.png"), dpi=300, bbox_inches="tight")
    plt.close()

    # 3. Readmission by Diagnosis Group
    print("\n3. Readmission Rate by Primary Diagnosis Group:")
    diag_analysis = (
        df.group_by("primary_diagnosis_group")
        .agg(
            total_encounters=pl.count(),
            readmitted_count=pl.sum("readmitted_binary"),
            readmission_rate=pl.col("readmitted_binary").mean() * 100
        )
        .sort("readmission_rate", descending=True)
    )
    print(diag_analysis)

    # Plot 2: Readmission by Diagnosis
    plt.figure(figsize=(10, 5))
    sns.barplot(
        x=diag_analysis["primary_diagnosis_group"].to_list(), 
        y=diag_analysis["readmission_rate"].to_list(), 
        palette="mako"
    )
    plt.title("Readmission Rate by Primary Diagnosis Group (Polars)")
    plt.ylabel("Readmission Rate (%)")
    plt.xlabel("Diagnosis Category")
    plt.xticks(rotation=15)
    plt.savefig(os.path.join(charts_dir, "readmission_by_diagnosis.png"), dpi=300, bbox_inches="tight")
    plt.close()

    # 4. Length of Stay Comparison
    print("\n4. Metrics by Readmission Status:")
    metrics = (
        df.group_by("readmitted_binary")
        .agg(
            avg_stay=pl.col("time_in_hospital").mean(),
            avg_lab_procedures=pl.col("num_lab_procedures").mean(),
            avg_medications=pl.col("num_medications").mean()
        )
    )
    print(metrics)
    print(f"\n📊 Visualizations saved to '{charts_dir}/' directory.")

if __name__ == "__main__":
    run_analysis()
