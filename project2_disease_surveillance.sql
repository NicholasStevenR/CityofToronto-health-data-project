-- ============================================================
-- Communicable Disease Surveillance SQL Pipeline
-- Author: Nicholas Steven
-- Target Role: Health Information Analyst, City of Toronto Public Health
-- Repo: github.com/nicholasstevenr/CityofToronto-health-data-project
-- ============================================================

-- ── Schema ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS cases (
    case_id       TEXT PRIMARY KEY,
    disease_code  TEXT NOT NULL,
    report_date   DATE NOT NULL,
    fsa           CHAR(3) NOT NULL,
    age_years     INTEGER,
    sex           TEXT CHECK (sex IN ('Male','Female','Unknown')),
    lab_confirmed BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS disease_ref (
    disease_code TEXT PRIMARY KEY,
    disease_name TEXT NOT NULL,
    category     TEXT  -- e.g. 'Respiratory', 'Enteric', 'Sexually Transmitted'
);

CREATE TABLE IF NOT EXISTS fsa_population (
    fsa        CHAR(3) PRIMARY KEY,
    population INTEGER NOT NULL
);

-- ── Weekly Incidence by Disease and FSA ──────────────────────────────────────

WITH weekly_counts AS (
    SELECT
        disease_code,
        fsa,
        STRFTIME('%Y', report_date)                              AS yr,
        CAST(STRFTIME('%W', report_date) AS INTEGER)             AS iso_week,
        COUNT(*)                                                 AS case_count
    FROM cases
    WHERE lab_confirmed = TRUE
    GROUP BY disease_code, fsa, yr, iso_week
),
incidence AS (
    SELECT
        wc.*,
        dr.disease_name,
        dr.category,
        fp.population,
        ROUND(wc.case_count * 100000.0 / fp.population, 2)      AS incidence_per_100k
    FROM weekly_counts wc
    JOIN disease_ref dr ON dr.disease_code = wc.disease_code
    JOIN fsa_population fp ON fp.fsa = wc.fsa
)
SELECT * FROM incidence
ORDER BY yr DESC, iso_week DESC, incidence_per_100k DESC;


-- ── Epidemic Threshold Detection (Mean + 2 SD logic) ─────────────────────────

WITH baseline AS (
    SELECT
        disease_code,
        fsa,
        AVG(case_count)                        AS mean_cases,
        -- Use 5-year baseline (weeks from prior years)
        (AVG(case_count * case_count) - AVG(case_count) * AVG(case_count)) AS variance
    FROM (
        SELECT disease_code, fsa,
               CAST(STRFTIME('%W', report_date) AS INTEGER) AS iso_week,
               COUNT(*) AS case_count
        FROM cases
        WHERE report_date < DATE('now', '-1 year')
        GROUP BY disease_code, fsa, iso_week
    ) hist
    GROUP BY disease_code, fsa
),
current_week AS (
    SELECT disease_code, fsa, COUNT(*) AS current_cases
    FROM cases
    WHERE report_date BETWEEN DATE('now', '-7 days') AND DATE('now')
    GROUP BY disease_code, fsa
)
SELECT
    cw.disease_code,
    cw.fsa,
    cw.current_cases,
    ROUND(bl.mean_cases, 2)                           AS baseline_mean,
    ROUND(bl.mean_cases + 2 * SQRT(bl.variance), 2)   AS epidemic_threshold,
    CASE WHEN cw.current_cases > bl.mean_cases + 2 * SQRT(bl.variance)
         THEN 'ALERT' ELSE 'Normal' END               AS alert_status
FROM current_week cw
JOIN baseline bl ON bl.disease_code = cw.disease_code AND bl.fsa = cw.fsa
ORDER BY alert_status DESC, cw.current_cases DESC;


-- ── Age-Sex Stratified Case Counts ───────────────────────────────────────────

SELECT
    dr.disease_name,
    CASE
        WHEN c.age_years BETWEEN 0 AND 4   THEN '0-4'
        WHEN c.age_years BETWEEN 5 AND 17  THEN '5-17'
        WHEN c.age_years BETWEEN 18 AND 34 THEN '18-34'
        WHEN c.age_years BETWEEN 35 AND 64 THEN '35-64'
        WHEN c.age_years >= 65             THEN '65+'
        ELSE 'Unknown'
    END                                              AS age_group,
    c.sex,
    COUNT(*)                                         AS case_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY dr.disease_name), 1) AS pct_of_disease_total
FROM cases c
JOIN disease_ref dr ON dr.disease_code = c.disease_code
WHERE STRFTIME('%Y', c.report_date) = STRFTIME('%Y', 'now')
GROUP BY dr.disease_name, age_group, c.sex
ORDER BY dr.disease_name, age_group, c.sex;


-- ── Cluster Detection: ≥3 cases, same FSA, same 2-week window ────────────────

SELECT
    a.disease_code,
    a.fsa,
    a.report_date                                    AS anchor_date,
    COUNT(b.case_id)                                 AS cases_in_window
FROM cases a
JOIN cases b
  ON  b.disease_code = a.disease_code
  AND b.fsa = a.fsa
  AND b.report_date BETWEEN a.report_date AND DATE(a.report_date, '+14 days')
GROUP BY a.disease_code, a.fsa, a.report_date
HAVING COUNT(b.case_id) >= 3
ORDER BY cases_in_window DESC;
