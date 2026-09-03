import os
import polars as pl
import matplotlib.pyplot as plt
import seaborn as sns

clean_path = "data/processed/clean_diabetic_data.csv"
charts_dir = "charts"

def run_analysis():
    """
    Performs comprehensive exploratory and clinical data analytics on the cleaned cohort
    using Polars aggregations, exporting visualizations to the charts/ directory.
    
    Clinical Focus Areas:
    ---------------------------------------------------------------------------
    1. Overall 30-Day Readmission Benchmark (CMS HRRP standard)
    2. Readmission Risk by Age Stratification
    3. Readmission Risk by Primary Clinical Diagnosis Group
    4. Impact of Prior Healthcare Utilization (Total Prior Visits)
    5. Glycemic Monitoring Impact (HbA1c test status)
    6. Medication Regimen Complexity (Active Diabetes Drug Count)
    """
    if not os.path.exists(clean_path):
        print(f"⚠️ Cleaned data file not found at '{clean_path}' to analyze.")
        return

    df = pl.read_csv(clean_path)
    os.makedirs(charts_dir, exist_ok=True)
    sns.set_theme(style="whitegrid", palette="deep")
    plt.rcParams.update({"font.size": 11, "figure.autolayout": True})

    print("================================================================")
    print("🏥 CLINICAL READMISSION ANALYTICS REPORT (POLARS PIPELINE)")
    print("================================================================")

    # -------------------------------------------------------------------------
    # 1. Overall Baseline Readmission Rate
    # -------------------------------------------------------------------------
    total_encounters = df.height
    unique_patients = df["patient_id"].n_unique()
    total_readmitted = df["readmitted_30d_binary"].sum()
    overall_rate = (total_readmitted / total_encounters) * 100

    print(f"\n1. Institutional Readmission Baseline:")
    print(f"   - Total Hospital Encounters: {total_encounters:,}")
    print(f"   - Unique Individual Patients: {unique_patients:,}")
    print(f"   - 30-Day Readmissions: {total_readmitted:,}")
    print(f"   - Baseline 30-Day Readmission Rate: {overall_rate:.2f}%")

    # -------------------------------------------------------------------------
    # 2. Readmission by Age Group
    # -------------------------------------------------------------------------
    age_df = (
        df.group_by("age_group")
        .agg(
            total_encounters=pl.len(),
            readmissions=pl.sum("readmitted_30d_binary"),
            readmission_rate_pct=(pl.col("readmitted_30d_binary").mean() * 100).round(2)
        )
        .sort("age_group")
    )
    print("\n2. Readmission Risk by Age Bracket:")
    print(age_df)

    # Visualization 1: Readmission by Age
    plt.figure(figsize=(9, 5))
    bar1 = sns.barplot(
        x=age_df["age_group"].to_list(),
        y=age_df["readmission_rate_pct"].to_list(),
        palette="Blues_d"
    )
    plt.axhline(overall_rate, color="red", linestyle="--", label=f"Cohort Average ({overall_rate:.1f}%)")
    plt.title("30-Day Readmission Rate by Age Group", fontweight="bold")
    plt.xlabel("Age Bracket")
    plt.ylabel("Readmission Rate (%)")
    plt.ylim(0, max(age_df["readmission_rate_pct"].to_list()) + 4)
    plt.legend()
    age_plot_path = os.path.join(charts_dir, "readmission_by_age.png")
    plt.savefig(age_plot_path, dpi=300)
    plt.close()

    # -------------------------------------------------------------------------
    # 3. Readmission by Primary Diagnosis Group
    # -------------------------------------------------------------------------
    diag_df = (
        df.group_by("primary_diagnosis_group")
        .agg(
            total_encounters=pl.len(),
            readmissions=pl.sum("readmitted_30d_binary"),
            readmission_rate_pct=(pl.col("readmitted_30d_binary").mean() * 100).round(2)
        )
        .sort("readmission_rate_pct", descending=True)
    )
    print("\n3. Readmission Risk by Primary Clinical Diagnosis:")
    print(diag_df)

    # Visualization 2: Readmission by Diagnosis
    plt.figure(figsize=(10, 5))
    bar2 = sns.barplot(
        x=diag_df["primary_diagnosis_group"].to_list(),
        y=diag_df["readmission_rate_pct"].to_list(),
        palette="Reds_d"
    )
    plt.axhline(overall_rate, color="blue", linestyle="--", label=f"Cohort Average ({overall_rate:.1f}%)")
    plt.title("30-Day Readmission Rate by Primary Diagnosis Group", fontweight="bold")
    plt.xlabel("Diagnosis Category (ICD-9 Grouped)")
    plt.ylabel("Readmission Rate (%)")
    plt.xticks(rotation=20, ha="right")
    plt.legend()
    diag_plot_path = os.path.join(charts_dir, "readmission_by_diagnosis.png")
    plt.savefig(diag_plot_path, dpi=300)
    plt.close()

    # -------------------------------------------------------------------------
    # 4. Prior Healthcare Utilization Impact
    # -------------------------------------------------------------------------
    df_with_tier = df.with_columns(
        pl.when(pl.col("total_prior_visits") == 0).then(pl.lit("0 Visits (Low)"))
        .when(pl.col("total_prior_visits").is_between(1, 2)).then(pl.lit("1-2 Visits (Moderate)"))
        .when(pl.col("total_prior_visits").is_between(3, 5)).then(pl.lit("3-5 Visits (High)"))
        .otherwise(pl.lit("6+ Visits (Super-utilizer)")).alias("utilization_tier")
    )

    util_df = (
        df_with_tier.group_by("utilization_tier")
        .agg(
            total_encounters=pl.len(),
            readmissions=pl.sum("readmitted_30d_binary"),
            readmission_rate_pct=(pl.col("readmitted_30d_binary").mean() * 100).round(2)
        )
        .sort("readmission_rate_pct")
    )
    print("\n4. Prior Healthcare Utilization Tier Impact:")
    print(util_df)

    # Visualization 3: Readmission by Prior Visits
    plt.figure(figsize=(8, 5))
    sns.barplot(
        x=util_df["utilization_tier"].to_list(),
        y=util_df["readmission_rate_pct"].to_list(),
        palette="Purples_d"
    )
    plt.title("Readmission Risk Escalation by Prior Visit Frequency", fontweight="bold")
    plt.xlabel("Prior Healthcare Visits (Outpatient + Emergency + Inpatient)")
    plt.ylabel("30-Day Readmission Rate (%)")
    util_plot_path = os.path.join(charts_dir, "readmission_by_prior_visits.png")
    plt.savefig(util_plot_path, dpi=300)
    plt.close()

    # -------------------------------------------------------------------------
    # 5. Glycemic Testing & HbA1c Monitoring
    # -------------------------------------------------------------------------
    a1c_df = (
        df.group_by("a1c_result_clean")
        .agg(
            total_encounters=pl.len(),
            readmissions=pl.sum("readmitted_30d_binary"),
            readmission_rate_pct=(pl.col("readmitted_30d_binary").mean() * 100).round(2)
        )
        .sort("readmission_rate_pct", descending=True)
    )
    print("\n5. HbA1c Glycemic Monitoring Impact:")
    print(a1c_df)

    # Visualization 4: HbA1c Results
    plt.figure(figsize=(8, 5))
    sns.barplot(
        x=a1c_df["a1c_result_clean"].to_list(),
        y=a1c_df["readmission_rate_pct"].to_list(),
        palette="Greens_d"
    )
    plt.title("30-Day Readmission Rate by HbA1c Test Result", fontweight="bold")
    plt.xlabel("HbA1c Result Category")
    plt.ylabel("Readmission Rate (%)")
    a1c_plot_path = os.path.join(charts_dir, "readmission_by_a1c.png")
    plt.savefig(a1c_plot_path, dpi=300)
    plt.close()

    # -------------------------------------------------------------------------
    # 6. Hospital Resource Consumption Comparison
    # -------------------------------------------------------------------------
    resource_df = (
        df.group_by("readmitted_30d_binary")
        .agg(
            cohort=pl.when(pl.col("readmitted_30d_binary") == 1).then(pl.lit("Readmitted (<30d)")).otherwise(pl.lit("Not Readmitted")),
            encounters=pl.len(),
            avg_stay=pl.col("length_of_stay").mean().round(2),
            avg_lab_procedures=pl.col("num_lab_procedures").mean().round(2),
            avg_medications=pl.col("num_medications").mean().round(2)
        )
    )
    print("\n6. Hospital Resource Consumption by Cohort:")
    print(resource_df)

    print(f"\n✅ Analysis complete! 4 high-resolution charts exported to '{charts_dir}/'.")

if __name__ == "__main__":
    run_analysis()
