# Patient Readmission Analysis

This repository contains a structured analytical pipeline to investigate and predict patient readmissions (within 30 days of discharge) using clinical records.

## Project Structure
```text
patient-readmission-analysis/
├── PROJECT.md                # Detailed project documentation, clinical goals, and metrics
├── README.md                 # Project quickstart and layout reference (this file)
├── sql/                      # SQL scripts for database preparation and cleaning
│   ├── 01_staging.sql        # Table definitions and initial data loading
│   ├── 02_profiling.sql      # Database-level EDA and statistical profiling
│   └── 03_cleaning_views.sql # Transformation views and feature preparation
├── notebooks/                # Python scripts and notebooks for modeling and visualization
│   └── analysis.ipynb        # Jupyter notebook containing python data analysis and ML models
└── charts/                   # Saved visualization outputs (PNGs/PDFs)
```

## Getting Started

### Prerequisites
- A SQL database engine (e.g., PostgreSQL, BigQuery, SQLite)
- Python 3.8+ with the following packages:
  - `pandas`
  - `numpy`
  - `matplotlib`
  - `seaborn`
  - `scikit-learn`
  - `sqlalchemy` (optional, for direct DB connection)
  - `jupyter` / `notebook`

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/bhargavna01/patient-readmission-analysis.git
   cd patient-readmission-analysis
   ```
2. Set up a virtual environment and install packages:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install pandas numpy matplotlib seaborn scikit-learn jupyter
   ```

### Execution Steps
1. **SQL Prep**: Run the SQL scripts in order:
   - Run `sql/01_staging.sql` to initialize your database structure.
   - Execute queries in `sql/02_profiling.sql` to profile the data.
   - Run `sql/03_cleaning_views.sql` to construct the transformed views for modeling.
2. **Analysis & Modeling**: Start Jupyter Notebook:
   ```bash
   jupyter notebook
   ```
   Open `notebooks/analysis.ipynb` to run the exploratory visualizations and train the predictive models.
