"""
Toronto Respiratory Disease Surveillance — Data Cleaning & Aggregation
Author: Nicholas Steven
Target Role: Health Information Analyst, City of Toronto Public Health
Repo: github.com/nicholasstevenr/CityofToronto-health-data-project

Cleans and aggregates synthetic Ontario respiratory illness data,
computing weekly incidence rates by FSA for Looker Studio dashboard.
"""

import pandas as pd
import numpy as np

# ── 1. Load synthetic data ────────────────────────────────────────────────────
def load_data(filepath: str) -> pd.DataFrame:
    df = pd.read_csv(filepath, parse_dates=["report_date"])
    return df


# ── 2. Standardize and clean ──────────────────────────────────────────────────
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    # Drop duplicate case records
    df = df.drop_duplicates(subset=["case_id"])

    # Standardize FSA codes: uppercase, strip whitespace
    df["fsa"] = df["fsa"].str.upper().str.strip()
    df = df[df["fsa"].str.match(r"^[A-Z]\d[A-Z]$")]

    # Normalize age groups
    age_bins = [0, 4, 17, 34, 64, 120]
    age_labels = ["0-4", "5-17", "18-34", "35-64", "65+"]
    df["age_group"] = pd.cut(df["age_years"], bins=age_bins, labels=age_labels, right=True)

    # Standardize sex column
    df["sex"] = df["sex"].str.lower().map({"m": "Male", "f": "Female", "male": "Male", "female": "Female"})

    # Add ISO week and year columns
    df["iso_week"] = df["report_date"].dt.isocalendar().week.astype(int)
    df["iso_year"] = df["report_date"].dt.isocalendar().year.astype(int)
    df["week_label"] = df["iso_year"].astype(str) + "-W" + df["iso_week"].astype(str).str.zfill(2)

    return df


# ── 3. Population lookup (synthetic — replace with actual Census data) ────────
FSA_POPULATION = {
    "M5V": 42000, "M5A": 31000, "M6H": 55000, "M4W": 28000,
    "M3N": 47000, "M1K": 38000, "M9W": 51000, "M2J": 34000,
}

def compute_incidence(df: pd.DataFrame) -> pd.DataFrame:
    weekly = (
        df.groupby(["week_label", "iso_year", "iso_week", "fsa", "age_group"])
        .size()
        .reset_index(name="case_count")
    )
    weekly["population"] = weekly["fsa"].map(FSA_POPULATION).fillna(35000)
    weekly["incidence_per_100k"] = (weekly["case_count"] / weekly["population"] * 100_000).round(2)
    return weekly


# ── 4. Year-over-year comparison ──────────────────────────────────────────────
def yoy_comparison(incidence: pd.DataFrame) -> pd.DataFrame:
    prev = incidence.copy()
    prev["iso_year"] += 1
    prev = prev.rename(columns={"incidence_per_100k": "incidence_prior_year"})
    merged = incidence.merge(
        prev[["iso_week", "fsa", "incidence_prior_year"]],
        on=["iso_week", "fsa"], how="left"
    )
    merged["yoy_change_pct"] = (
        (merged["incidence_per_100k"] - merged["incidence_prior_year"])
        / merged["incidence_prior_year"].replace(0, np.nan) * 100
    ).round(1)
    return merged


# ── 5. Export for Looker Studio (Google Sheets CSV) ───────────────────────────
def export(df: pd.DataFrame, outpath: str) -> None:
    df.to_csv(outpath, index=False)
    print(f"Exported {len(df)} rows to {outpath}")


# ── Main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    raw = load_data("data/respiratory_cases_raw.csv")
    cleaned = clean_data(raw)
    incidence = compute_incidence(cleaned)
    final = yoy_comparison(incidence)
    export(final, "output/toronto_respiratory_dashboard_data.csv")
    print("Summary statistics:")
    print(final[["incidence_per_100k", "yoy_change_pct"]].describe().round(2))
