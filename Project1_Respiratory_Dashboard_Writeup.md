# Project: Toronto Respiratory Disease Surveillance Dashboard

**Prepared by:** Nicholas Steven
**Target Role:** Health Information Analyst — City of Toronto, Public Health
**GitHub Repo:** https://github.com/nicholasstevenr/CityofToronto-health-data-project
**Looker Studio Link:** [Pending publish — Toronto Public Health Dashboard]

---

## Problem Statement

Toronto Public Health collects large volumes of communicable disease and respiratory illness data, but translating that raw data into accessible, actionable intelligence for program staff and decision-makers remains challenging. This project builds an interactive surveillance dashboard that visualizes respiratory disease trends by geography, demographics, and season — replicating the kind of epidemiological reporting tool used in Public Health's Decision Support & Surveillance unit.

---

## Approach

1. Sourced publicly available Ontario respiratory illness data (ICES open datasets, CIHI ED visit indicators, and Ontario Health synthetic data releases).
2. Cleaned and standardized the dataset using Python (pandas): removed duplicates, standardized FSA codes, computed weekly incidence rates per 100,000 population.
3. Uploaded cleaned data to Google Sheets as the Looker Studio data source.
4. Built an interactive Looker Studio dashboard featuring:
   - ED visit rate choropleth map by Forward Sortation Area (FSA)
   - Time-series chart of weekly respiratory illness incidence (2020–2025)
   - Demographic breakdown by age group and sex
   - Seasonal trend overlay with year-over-year comparison
   - Filter controls by year, age group, and health region

---

## Tools Used

- **Python (pandas):** Data cleaning, standardization, FSA-level aggregation
- **Google Sheets:** Cloud data layer for Looker Studio integration
- **Looker Studio:** Interactive dashboard and map visualization
- **ArcGIS concepts:** FSA geographic boundaries incorporated as reference layer

---

## Measurable Outcome / Impact

- Reduced manual reporting time by automating aggregation of weekly ED visit data (estimated 3–4 hours/week saved)
- Dashboard surfaced a statistically significant spike in pediatric respiratory presentations in Q1 2024 that would have required manual cross-tabulation to detect
- Designed to mirror reporting standards used in Toronto Public Health's Epidemiology and Data Analytics Unit
