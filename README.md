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
     ```
   - Example URI structure:
     ```text
     postgresql://neondb_owner:npg_SuofE2s6HWiV@ep-dry-flower-ayu8lyw9-pooler.c-5.us-east-2.aws.neon.tech/neondb?sslmode=require
     ```
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
├── .github/                  # GitHub Actions CI workflows & integrations
│   └── workflows/
├── .vscode/                  # VS Code workspace settings & SQLTools configuration
│   └── settings.json
├── charts/                   # Visualizations, EDA charts, and ROC/PR curve exports
├── notebooks/                # Python analysis & predictive modeling
│   └── analysis.ipynb        # Jupyter notebook with ML classifiers (RandomForest, XGBoost)
├── sql/                      # Modular SQL pipeline scripts
│   ├── 01_staging.sql        # Table definitions, schemas, and primary indexing
│   ├── 02_profiling.sql      # In-database profiling, null audits, and distributions
│   └── 03_cleaning_views.sql # Transformation views, ICD-9 groupings, and feature encoding
├── .env.local                # Local environment secrets (ignored by Git)
├── .gitignore                # Git exclusion rules
├── import_data_polars.py     # High-speed ADBC CSV-to-Neon ingestion pipeline
├── PROJECT.md                # In-depth clinical background, metrics, and data dictionary
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
pip install polars adbc-driver-postgresql pandas numpy matplotlib seaborn scikit-learn jupyter python-dotenv
```

### 2. Configure Environment
Create `.env.local` in the project root:
```env
DATABASE_URL="postgresql://neondb_owner:YOUR_PASSWORD@ep-dry-flower-ayu8lyw9-pooler.c-5.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

### 3. Run Database Setup & Ingestion
1. **Initialize Schemas**: Run `sql/01_staging.sql` in SQLTools or via `psql`.
2. **Ingest Raw Data**:
   ```bash
   python import_data_polars.py
   ```
3. **Profile the Data**: Execute `sql/02_profiling.sql` to check data distributions and missing values.
4. **Create Analytical Views**: Execute `sql/03_cleaning_views.sql` to build clean, model-ready feature views.

### 4. Run Machine Learning & EDA
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

## 📄 License & Attribution
- **Dataset**: [UCI Diabetes 130-US Hospitals (1999-2008) Dataset](https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008).
- **Author / Maintainer**: [bhargavna01](https://github.com/bhargavna01).
