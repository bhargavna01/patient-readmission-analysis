# 🏥 Patient Readmission Analysis

[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL_16-blue?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Neon](https://img.shields.io/badge/Cloud_DB-Neon_Serverless-00E599?logo=neon&logoColor=white)](https://neon.tech)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Polars](https://img.shields.io/badge/Data_Engine-Polars-CD792C?logo=polars&logoColor=white)](https://pola.rs/)
[![Repository](https://img.shields.io/badge/GitHub-bhargavna01%2Fpatient--readmission--analysis-181717?logo=github&logoColor=white)](https://github.com/bhargavna01/patient-readmission-analysis)

A structured, end-to-end clinical data analytics and machine learning pipeline to investigate, profile, and predict 30-day patient hospital readmissions using historical electronic health records (EHR).

---

## 📑 Table of Contents
1. [Project Overview](#-project-overview)
2. [Why Choose Neon Serverless PostgreSQL?](#-why-choose-neon-serverless-postgresql)
3. [Step 1: Creating a Neon Account](#-step-1-creating-a-neon-account)
4. [Step 2: Deploying & Provisioning PostgreSQL on Neon](#-step-2-deploying--provisioning-postgresql-on-neon)
5. [Step 3: Connecting Neon with Visual Studio Code](#-step-3-connecting-neon-with-visual-studio-code)
6. [Step 4: Connecting Neon with GitHub Repository](#-step-4-connecting-neon-with-github-repository)
7. [Repository Structure](#-repository-structure)
8. [End-to-End Pipeline Execution](#-end-to-end-pipeline-execution)
9. [Database Branching Strategy](#-database-branching-strategy)
10. [Troubleshooting & Best Practices](#-troubleshooting--best-practices)

---

## 🔍 Project Overview

Hospital readmissions within 30 days of discharge serve as a critical quality-of-care metric and represent billions in healthcare costs. This project implements a dual analytical pipeline:
- **Relational SQL Pipeline (PostgreSQL on Neon)**: Staging, data profiling, categorical encoding, and feature transformation views directly on the database engine.
- **High-Performance Python Pipeline (Polars & Scikit-Learn)**: Multi-threaded data ingestion via ADBC, exploratory data analysis (EDA), and machine learning classification (ROC-AUC / Recall optimization).

---

## 💡 Why Choose Neon Serverless PostgreSQL?

For this clinical data engineering and analytics project, **[Neon](https://neon.tech)** was selected over traditional local PostgreSQL or heavy cloud instances (AWS RDS / GCP Cloud SQL) for the following reasons:

| Feature | Neon Serverless PostgreSQL | Traditional Local/Cloud Postgres |
| :--- | :--- | :--- |
| **Setup & Maintenance** | Instant provisioning in 10 seconds; zero local engine installs or background services | Requires manual daemon configuration, port binding, and OS-level maintenance |
| **Autoscaling & Scale-to-Zero** | Compute automatically pauses when idle (0% resource usage), waking up instantly on query | Runs 24/7 incurring continuous compute costs or local RAM consumption |
| **Database Branching** | Instant, copy-on-write database branches (like Git branches) for testing staging/ETL scripts safely | Requires tedious database dumps, replication setups, or shared test databases |
| **Polars & Python Integration** | High-performance pooled connection endpoints (`-pooler`) compatible with ADBC, SQLAlchemy, and Psycopg | Manual connection pooler setup (PgBouncer) needed for concurrent analytical workloads |
| **GitHub CI/CD Integration** | Official GitHub Actions and Neon GitHub App for automated preview databases per Pull Request | Requires complex provisioning scripts or ephemeral Docker containers in CI |
| **Cost & Generous Free Tier** | Free tier includes 0.5 GiB storage, compute allowance, and multiple branches | Paid hourly or complex billing models |

---

## 🚀 Step 1: Creating a Neon Account

Follow these steps to set up your free Neon account:

1. **Navigate to the Neon Website**:
   - Open your browser and go to **[https://neon.tech](https://neon.tech)**.
2. **Sign Up**:
   - Click the **"Sign Up"** or **"Get Started"** button in the top-right corner.
   - Choose your sign-in provider (Signing in with **GitHub** is recommended as it seamlessly links with your repository workflow).
3. **Authorize and Verify**:
   - Grant read permissions for authentication if using GitHub/Google, or verify your email address.
4. **Access the Console**:
   - Once verified, you will be automatically redirected to the **Neon Cloud Console** (`https://console.neon.tech/app/projects`).

---

## 🛠️ Step 2: Deploying & Provisioning PostgreSQL on Neon

Once logged in, deploy your managed PostgreSQL database cluster:

1. **Create a New Project**:
   - In the Neon Console dashboard, click **"New Project"** (or **"Create Project"**).
2. **Configure Project Details**:
   - **Project Name**: `patient-readmission-analysis` (or your preferred name).
   - **Postgres Version**: Select `Postgres 16` (recommended default).
   - **Primary Region**: Choose the region geographically closest to you or your application compute (e.g., `AWS us-east-2 (Ohio)`).
3. **Deploy**:
   - Click **"Create Project"**. Neon provisions your serverless Postgres cluster in under 10 seconds.
4. **Copy & Save Your Credentials**:
   - A dialog titled **"Connection Details"** will appear with your database credentials.
   - Select **"PostgreSQL"** or **"Connection string (URI)"** format:
     ```text
     postgresql://[user]:[password]@[host]/[database]?sslmode=require
      
   > ⚠️ **Important**: Save your password immediately. Neon passwords are generated securely and shown once during initial role creation.

---

## 💻 Step 3: Connecting Neon with Visual Studio Code

You can interact with your Neon database inside VS Code using graphical extensions, the built-in terminal, or Python scripts.

### Method A: Using SQLTools Extension (Recommended GUI)

1. **Install SQLTools**:
   - Open VS Code Extensions view (`Ctrl+Shift+X` or `Cmd+Shift+X`).
   - Search for and install:
     - **SQLTools** (`mtxr.sqltools`)
     - **SQLTools PostgreSQL Driver** (`mtxr.sqltools-driver-pg`)
2. **Configure Connection**:
   - You can configure the connection via the SQLTools UI or by updating `.vscode/settings.json` in this workspace:
     ```json
     {
       "sqltools.connections": [
         {
           "name": "Neon Serverless PostgreSQL (Patient Readmission)",
           "driver": "PostgreSQL",
           "server": "ep-dry-flower-ayu8lyw9-pooler.c-5.us-east-2.aws.neon.tech",
           "port": 5432,
           "database": "neondb",
           "username": "neondb_owner",
           "password": "YOUR_NEON_PASSWORD",
           "askForPassword": false,
           "ssl": {
             "rejectUnauthorized": false
           }
         }
       ]
     }
     ```
3. **Connect & Query**:
   - Click the **SQLTools** icon in the VS Code sidebar.
   - Click **Connect** next to your Neon database.
   - Open any `.sql` file in `sql/` (e.g., `01_staging.sql`) and click **"Run on active connection"** or press `Cmd+E Cmd+E` (`Ctrl+E Ctrl+E`).

---

### Method B: Native `psql` CLI in VS Code Terminal

If you have the PostgreSQL command-line client (`psql`) installed, open the VS Code Terminal (`Ctrl+\`` or `Cmd+\``) and run:

```bash
psql "postgresql://neondb_owner:YOUR_PASSWORD@ep-dry-flower-ayu8lyw9-pooler.c-5.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

---

### Method C: Connecting via Python & Polars (`.env.local`)

1. Create a `.env.local` file in the project root:
   ```env
   DATABASE_URL="postgresql://neondb_owner:YOUR_PASSWORD@ep-dry-flower-ayu8lyw9-pooler.c-5.us-east-2.aws.neon.tech/neondb?sslmode=require"
   ```
2. Ingest data using Polars with Apache Arrow ADBC engine:
   ```bash
   python import_data_polars.py
   ```

---

## 🔗 Step 4: Connecting Neon with GitHub Repository

Integrating Neon with your GitHub repository ([`bhargavna01/patient-readmission-analysis`](https://github.com/bhargavna01/patient-readmission-analysis)) enables automated testing, CI/CD database migrations, and isolated preview branches for Pull Requests.

### 1. Storing Database Secrets in GitHub Actions

To allow GitHub Actions CI workflows to communicate with your Neon PostgreSQL database securely without exposing credentials:

1. Navigate to your repository on GitHub: `https://github.com/bhargavna01/patient-readmission-analysis`.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Click **"New repository secret"** and add:
   - `DATABASE_URL`: Your full pooled connection URI (`postgresql://...`).
   - `PGHOST`: Your Neon host address (e.g., `ep-dry-flower-...aws.neon.tech`).
   - `PGDATABASE`: `neondb`.
   - `PGUSER`: `neondb_owner`.
   - `PGPASSWORD`: Your secure Neon database password.
4. Click **Add secret**.

---

### 2. Setting up Neon GitHub Integration (Automatic Preview Branches)

Neon provides an official GitHub integration that creates an isolated database branch for each Pull Request (PR) and drops it upon merging:

1. In the **Neon Console**, select your project.
2. Go to **Project Settings** > **Integrations** > **GitHub**.
3. Click **"Connect GitHub"** and authorize the Neon application.
4. Select the repository: `bhargavna01/patient-readmission-analysis`.
5. Neon will automatically manage preview database branches for test runs, ensuring your production/staging data remains untouched.

---

### 3. Example GitHub Actions CI Workflow (`.github/workflows/ci.yml`)

Create `.github/workflows/ci.yml` in your repo to run SQL migrations and data validation on every push:

```yaml
name: CI & Database Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-database:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Dependencies
        run: |
          pip install polars adbc-driver-postgresql python-dotenv scikit-learn

      - name: Execute SQL Staging & Profiling
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          python -c "
          import os, polars as pl
          uri = os.environ['DATABASE_URL']
          print('Testing Neon Connection...')
          df = pl.read_database_uri('SELECT 1 AS status', uri, engine='adbc')
          print(df)
          "
```

---

## 📁 Repository Structure

```text
patient-readmission-analysis/
├── .github/                  # GitHub Actions CI workflows & auto-analysis triggers
│   └── workflows/
│       └── auto_analysis.yml # Daily automated notebook execution & git push workflow
├── .vscode/                  # VS Code workspace settings & SQLTools configuration
│   └── settings.json
├── data/                     # Subdirectory for raw and processed datasets (ignored by Git)
│   ├── raw/
│   └── processed/
├── docs/                     # Detailed project specifications and reports
│   ├── data_dictionary.md    # Schema profiles of staging and cleaned data
│   ├── data_quality_report.md# Missingness, inclusion criteria, and PHI audits
│   └── methodology.md        # Comparative framework of Polars vs. PostgreSQL
├── charts/                   # Visualizations, EDA charts, and ROC/PR curve exports
├── notebooks/                # Python analysis & predictive modeling
│   └── analysis.ipynb        # Jupyter notebook with ML classifiers (RandomForest, Random Forest)
├── sql/                      # Modular SQL pipeline scripts
│   ├── 01_staging.sql        # Table definitions, staging ingestion, and indexes
│   ├── 02_profiling.sql      # Database profiling and distribution audits
│   ├── 03_quality_checks.sql # Constraints, duplicates, and HIPAA PHI checks
│   ├── 04_cleaning.sql       # Transforming views, ICD-9 groupings, and target variables
│   ├── 05_validation.sql     # Post-cleaning validations & structural checks
│   └── 06_analysis.sql       # Aggregated reporting queries on readmissions
├── polars/                   # Parallel data pipeline using Python Polars
│   ├── 01_load.py            # Loading raw data and db staging uploads
│   ├── 02_profiling.py       # Polars profiling statistical summaries
│   ├── 03_quality_checks.py  # Duplicates and value boundary assertions
│   ├── 04_cleaning.py        # Maps diagnosis codes and clean features
│   ├── 05_validation.py      # Cleansing validation & schema checks
│   └── 06_analysis.py        # Report tables and chart generation
├── .env                      # Local environment configuration secrets (ignored by Git)
├── .gitignore                # Git exclusion rules
├── requirements.txt          # Python library dependencies (polars, pandas, etc.)
├── PROJECT.md                # High-level project objectives & workflow stages
└── README.md                 # Full project documentation & step-by-step guide (this file)
```

---

## ⚡ End-to-End Pipeline Execution

Follow these steps to run the complete analysis locally:

### 1. Clone & Set Up Python Environment
```bash
git clone https://github.com/bhargavna01/patient-readmission-analysis.git
cd patient-readmission-analysis

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate    # On Windows: venv\Scripts\activate

# Install required dependencies
pip install -r requirements.txt
```

### 2. Configure Environment
Create a `.env` file in the project root:
```env
DATABASE_URL="postgresql://neondb_owner:npg_rgwvOKePYN93@ep-dry-flower-ayu8lyw9-pooler.c-5.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require"
```

### 3. Run the SQL Pipeline
1. **Staging & Ingestion**: Execute `sql/01_staging.sql` to create staging tables and load all raw encounters.
2. **Profiling**: Execute `sql/02_profiling.sql` to analyze distributions and verify raw statistics.
3. **Data Quality Checks**: Execute `sql/03_quality_checks.sql` to run duplicates and HIPAA compliance verification.
4. **Data Cleaning**: Execute `sql/04_cleaning.sql` to define the analytical clean view.
5. **Post-Clean Validation**: Execute `sql/05_validation.sql` to run schema constraints and range validation.
6. **Aggregated Analysis**: Run `sql/06_analysis.sql` to pull readmission metrics directly in SQL.

### 4. Run the Polars Pipeline
Alternatively, run the Python-based data engineering pipeline:
```bash
python3 polars/01_load.py             # Load raw CSV and stage to database
python3 polars/02_profiling.py        # Generate statistical summaries
python3 polars/03_quality_checks.py   # Run null and duplicate quality tests
python3 polars/04_cleaning.py         # Standardize features and group ICD codes
python3 polars/05_validation.py       # Assert cleaned data constraints
python3 polars/06_analysis.py         # Generate reporting tables and save charts
```

### 5. Run Machine Learning & EDA
Start Jupyter Notebook to execute the modeling pipeline:
```bash
jupyter notebook notebooks/analysis.ipynb
```

---

## 🌿 Database Branching Strategy

Neon's copy-on-write branching feature is utilized across the project lifecycle:

- **`main` (Production Branch)**: Houses validated clinical data schemas and production transformation views.
- **`dev-analytics` (Development Branch)**: Used for experimental feature engineering, trial table mutations, and testing complex SQL window functions without impacting the main dataset.
- **Pull Request Branches**: Ephemeral branches automatically spun up by GitHub Actions to validate data schema migrations during code reviews.

To create a branch using the Neon CLI:
```bash
# Install Neon CLI
npm install -g neonctl

# Authenticate & create a branch
neonctl auth
neonctl branches create --name dev-analytics
```

---

## 🛡️ Troubleshooting & Best Practices

1. **SSL Required Error**:
   - Always ensure `?sslmode=require` is appended to connection strings.
   - In SQLTools, set `"ssl": { "rejectUnauthorized": false }`.
2. **Compute Scale-to-Zero Latency (Cold Start)**:
   - When querying a Neon instance after an idle period, the first query may take 500ms–1s while the serverless compute wakes up. Subsequent queries execute with sub-millisecond latencies.
3. **Use Connection Pooling for Analytical Scripts**:
   - Use the `-pooler` endpoint (e.g., `ep-dry-flower-...-pooler...`) for applications with multiple concurrent connections or high-throughput batch writes.
4. **Security Notice**:
   - Never commit `.env.local` or raw passwords to GitHub. Ensure `.gitignore` includes all environment configuration and sensitive data exports.

---

## 🔒 Compliance Audits & Pipeline Execution History

The first three stages of the SQL pipeline were executed successfully on the Neon cloud database.

### 1. Ingestion Audit (`01_staging.sql`)
- **Action**: Staged raw encounters from `public.diabetic_data` into `staging.raw_clinical_records`.
- **Result**: Successfully ingested exactly **101,766** patient records. Primary index keys were applied on `encounter_id` and indices mapped on `patient_id` and `readmitted_flag` for search speed.

### 2. Demographic & Outlier Profiling (`02_profiling.sql`)
- **Patient Volume**: Audited 101,766 total encounters representing **71,518** unique patients (with 0 duplicate `encounter_id` instances).
- **Dynamic Schema Profiling (JSONB Unnesting)**: Implemented an advanced PostgreSQL unnesting query using `LATERAL jsonb_each_text(to_jsonb(t))` to dynamically pivot and audit all 50 columns in a single query. This query maps non-standard clinical missing placeholders (`?`, `None`, `""`) to SQL NULLs, joins metadata from `information_schema.columns` to fetch physical data types, and outputs sorted missingness statistics.
- **Top Sparse Columns Audited**:
  - `weight` (96.86% missing)
  - `max_glu_serum` (94.75% missing)
  - `A1Cresult` (83.28% missing)
  - `medical_specialty` (49.08% missing)
  - `payer_code` (39.56% missing)
- **Target Distribution**: Found 53.91% records had no readmission, 11.16% readmitted in under 30 days, and 34.93% readmitted in over 30 days.
- **Length of Stay**: Evaluated average hospital stay durations: 4.77 days for <30 readmissions, 4.50 days for >30 readmissions, and 4.25 days for no readmission.

### 3. HIPAA & HL7 Compliance Checks (`03_quality_checks.sql`)
- **Direct Identifiers check (HIPAA Safe Harbor)**: Verified that no columns leaked PHI (Protected Health Information). Specifically, we audited string text columns for names, SSNs, and ZIP code formats; **0 leaks** were found. The database represents a fully de-identified research corpus.
- **Clinical Terminology Consistency (HL7/ICD-9)**: Audited primary diagnosis ICD-9 codes. Verified that only 3 records had invalid gender categories, and 21 records lacked primary diagnostics (which are cleaned and grouped in the next stages).

### 4. Comprehensive Clinical Data Cleaning (`04_cleaning.sql` & `polars/04_cleaning.py`)
- **Coverage**: Applied data cleaning and clinical transformations across **all 50 columns** of the raw EHR dataset.
- **Key Transformations & Clinical Rationale**:
  1. **Cohort Exclusion (HIPAA & Demographic Quality)**: Excluded exactly 3 records where `gender` was recorded as `'Unknown/Invalid'`, producing a clean cohort of **101,763** encounters and **71,515** unique patients.
  2. **CMS 30-Day Readmission Standard**: Binarized the target variable based on the CMS Hospital Readmissions Reduction Program (HRRP) definition: `<30` days was mapped to `1` (positive readmission: 11,357 encounters, 11.16%), while `>30` and `NO` were mapped to `0` (90,406 encounters, 88.84%).
  3. **ICD-9 Clinical Taxonomy Grouping**: Mapped raw primary (`diag_1`), secondary (`diag_2`), and tertiary (`diag_3`) codes into 9 standardized clinical clusters: Circulatory (390–459, 785), Respiratory (460–519, 786), Digestive (520–579, 787), Diabetes (250.xx), Genitourinary (580–629, 788), Neoplasms (140–239), Musculoskeletal (710–739), Injury (800–999), and Other.
  4. **Medication Normalization (24 Diabetes Drugs)**: Standardized dosage statuses (`No`, `Steady`, `Up`, `Down`) across all 23 active medications (and 1 constant drug), aliased hyphenated column names for ANSI SQL compliance, and engineered an `active_med_count` metric.
  5. **Utilization Aggregation**: Engineered `total_prior_visits` by summing outpatient, emergency, and inpatient encounters over the preceding 12 months.
  6. **Glycemic Monitoring (HbA1c & Glucose)**: Standardized `None` entries to `'Not Tested'`, isolating glycemic monitoring cohorts (`Norm`, `>7`, `>8`).
- **Dual Pipeline Implementation**:
  - **SQL View**: Deployed as `staging.v_clean_patient_data` on Neon PostgreSQL.
  - **Polars Pipeline**: Produced the standardized analytical dataset `data/processed/clean_diabetic_data.csv` (101,763 rows × 73 columns).

### 5. Post-Cleaning Data Validation (`05_validation.sql` & `polars/05_validation.py`)
- **Validation Suite**: Executed 5 rigorous automated tests across both the relational database and Python in-memory engines:
  1. **Cohort Drop Assertion**: Confirmed raw (101,766) - clean (101,763) = exactly 3 rows dropped (**PASSED**).
  2. **Gender Domain Constraint**: Confirmed gender strictly contains `['Male', 'Female']` (**PASSED**).
  3. **Target Invariant**: Confirmed target variable strictly contains binary `{0, 1}` with exactly 11,357 positive events (**PASSED**).
  4. **Critical Field Completeness**: Confirmed 0 null values across all demographic, diagnostic, and target fields (**PASSED**).
  5. **Clinical Range Validation**: Confirmed 100% compliance of hospital length of stay within 1 to 14 days (**PASSED**).

### 6. Exploratory Clinical Analytics & Key Drivers (`06_analysis.sql` & `polars/06_analysis.py`)
- **Institutional Baseline**: 101,763 encounters across 71,515 unique patients exhibited an overall 30-day readmission rate of **11.16%**.
- **Clinical Findings**:
  1. **Prior Healthcare Utilization (Primary Signal)**: Readmission risk escalates sharply with prior visit frequency:
     - 0 Prior Visits: **8.18%** readmission rate
     - 1–2 Prior Visits: **12.59%** readmission rate
     - 3–5 Prior Visits: **16.39%** readmission rate
     - 6+ Prior Visits (Super-utilizers): **25.51%** readmission rate (a **3.1x risk elevation**).
  2. **Clinical Diagnosis Vulnerability**: Highest readmission rates were observed in patients admitted for **Diabetes** (12.98%) and **Injury** (12.25%). **Circulatory conditions** represented the largest clinical volume (30,436 encounters, 11.45% readmission rate).
  3. **Glycemic Testing Protective Effect**: Patients who did not receive an HbA1c test had a higher readmission rate (**11.42%**) than those who received testing (**9.66% – 10.05%**), demonstrating the clinical benefit of active glycemic surveillance.
  4. **Resource Consumption**: Readmitted patients exhibited significantly higher average length of stay (4.77 days vs. 4.35 days), higher average laboratory procedures (44.2 vs. 42.9), and higher average medication counts (16.9 vs. 15.9).
- **Generated Visualizations**:
  - `charts/readmission_by_age.png`
  - `charts/readmission_by_diagnosis.png`
  - `charts/readmission_by_prior_visits.png`
  - `charts/readmission_by_a1c.png`

---

## 📄 License & Attribution
- **Dataset**: [UCI Diabetes 130-US Hospitals (1999-2008) Dataset](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008).
- **Author / Maintainer**: [bhargavna01](https://github.com/bhargavna01).
