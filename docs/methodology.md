# Methodology: Polars vs. PostgreSQL (PSQL) Benchmarking

This project executes data engineering and data analysis pipelines side-by-side using two separate systems to compare their development ergonomics, execution efficiency, and syntax readability.

## 1. Technical Framework

We compare two distinct execution strategies:

```
                  [ Raw Data: diabetic_data.csv ]
                                 │
         ┌───────────────────────┴───────────────────────┐
         ▼                                               ▼
   [ SQL Pipeline ]                              [ Polars Pipeline ]
   - Database Engine: PostgreSQL                 - Engine: Polars (Python)
   - Host: Neon Serverless Cloud                 - Architecture: Arrow In-Memory
   - Syntax: Declarative SQL                     - Syntax: Lazy/Eager expression API
```

### Approach A: PostgreSQL (Neon Serverless Cloud)
- **Architecture**: Queries are executed in the database engine using SQL.
- **Data Movement**: Staging data is stored in tables; cleaning is done via logical database views (`staging.v_clean_patient_data`).
- **Use Case**: Simulates the standard database-first analytical model (ELT/ETL).

### Approach B: Polars (In-Memory Python)
- **Architecture**: Executed locally or in-memory using multi-threaded execution built on Apache Arrow.
- **Data Movement**: CSV datasets are read directly; cleaning is done using the Polars Expression API, outputting processed files to disk (`data/processed/`).
- **Use Case**: Simulates the data-science-first in-memory processing model.

---

## 2. Comparison Metrics

During the development and testing of both pipelines, we benchmark the following:

| Evaluation Aspect | PostgreSQL / PSQL | Polars |
|---|---|---|
| **Development Ergonomics** | Declarative SQL queries. Very structured, excellent for standard reporting. | Python API. Supports object-oriented flows, modular scripting, and seamless integration with ML models. |
| **Execution Model** | Relational planner with query optimization and index scanning. | Multi-threaded lazy evaluation with query optimization. |
| **Data Locality** | Out-of-memory. Data stays inside the cloud database; query sends only aggregates back. | In-memory. Relies on local memory footprints (ideal for local execution of <10GB data). |
| **Pipelining** | Handled through scheduled SQL statements or dbt configurations. | Python packages/workflows (e.g. GitHub Actions, Apache Airflow). |
