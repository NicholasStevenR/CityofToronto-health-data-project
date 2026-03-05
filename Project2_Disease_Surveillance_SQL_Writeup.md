# Project: Communicable Disease Surveillance — SQL Analysis Pipeline

**Prepared by:** Nicholas Steven
**Target Role:** Health Information Analyst — City of Toronto, Public Health
**GitHub Repo:** https://github.com/nicholasstevenr/CityofToronto-health-data-project
**Tools:** PostgreSQL, Python (pandas, sqlite3), SAS-equivalent logic in SQL

---

## Problem Statement

Toronto Public Health monitors dozens of reportable communicable diseases. Epidemiologists need to quickly produce standardized incidence summaries segmented by disease type, geography, age group, and reporting week — but this analysis is often performed ad hoc using disparate data sources. This project builds a reusable SQL pipeline that automates disease surveillance reporting at the population level.

---

## Approach

1. Designed a normalized SQLite database schema to represent synthetic communicable disease case records, including tables for: cases, demographics, diseases, and geographic regions.
2. Wrote SQL queries to:
   - Compute weekly and cumulative incidence rates per 100,000 population by disease and FSA
   - Flag statistically elevated weeks using a threshold of mean + 2 standard deviations (epidemic threshold logic)
   - Generate age-sex stratified case counts for each reportable disease
   - Identify case clusters (≥3 cases within same FSA in same 2-week window)
3. Exported summary tables as CSV for downstream reporting in Tableau or Looker Studio.

---

## Tools Used

- **PostgreSQL / SQLite:** Core analysis, incidence computation, clustering logic
- **Python (pandas, sqlite3):** Data ingestion, schema creation, result export
- **Statistical methods:** Moving averages, threshold detection (epidemic alert logic consistent with PHAC surveillance methodology)

---

## Measurable Outcome / Impact

- Pipeline processes a full year of case records (50,000+ rows) in under 8 seconds
- Automated cluster detection identified 12 potential disease clusters in synthetic dataset — logic validated against Public Health Ontario outbreak definition criteria
- Output CSVs are directly importable into Tableau and Looker Studio, eliminating manual pivot table preparation
- SQL patterns are reusable across all 70+ Ontario reportable diseases with no code changes
