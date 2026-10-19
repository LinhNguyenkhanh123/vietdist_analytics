CREATE TABLE dwh.dim_date (
    date_key           INTEGER PRIMARY KEY,
    date_actual        DATE NOT NULL UNIQUE,
    calendar_year      INTEGER NOT NULL,
    calendar_quarter   INTEGER NOT NULL,
    month_number       INTEGER NOT NULL,
    month_name         TEXT NOT NULL,
    day_of_month       INTEGER NOT NULL,
    day_of_week        INTEGER NOT NULL,
    day_name           TEXT NOT NULL,
    week_of_year       INTEGER NOT NULL,
    iso_year           INTEGER NOT NULL,
    is_weekend         BOOLEAN NOT NULL,
    fiscal_year        INTEGER NOT NULL,
    fiscal_quarter     INTEGER NOT NULL
);

INSERT INTO dwh.dim_date (
    date_key,
    date_actual,
    calendar_year,
    calendar_quarter,
    month_number,
    month_name,
    day_of_month,
    day_of_week,
    day_name,
    week_of_year,
    iso_year,
    is_weekend,
    fiscal_year,
    fiscal_quarter
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_key,
    d::DATE AS date_actual,
    EXTRACT(YEAR FROM d)::INTEGER AS calendar_year,
    EXTRACT(QUARTER FROM d)::INTEGER AS calendar_quarter,
    EXTRACT(MONTH FROM d)::INTEGER AS month_number,
    TO_CHAR(d, 'FMMonth') AS month_name,
    EXTRACT(DAY FROM d)::INTEGER AS day_of_month,
    -- Day of week: Monday = 1, Sunday = 7
    EXTRACT(ISODOW FROM d)::INTEGER AS day_of_week,
    TO_CHAR(d, 'FMDay') AS day_name,
    -- ISO week/year can differ from calendar year near New Year
    EXTRACT(WEEK FROM d)::INTEGER AS week_of_year,
    EXTRACT(ISOYEAR FROM d)::INTEGER AS iso_year,
    EXTRACT(ISODOW FROM d)::INTEGER IN (6, 7) AS is_weekend,
    -- Fiscal year starts in September
    CASE
        WHEN EXTRACT(MONTH FROM d) >= 9
            THEN EXTRACT(YEAR FROM d)::INTEGER
        ELSE EXTRACT(YEAR FROM d)::INTEGER - 1
    END AS fiscal_year,
    ((EXTRACT(MONTH FROM d)::INTEGER + 3) % 12) / 3 + 1
        AS fiscal_quarter

FROM GENERATE_SERIES(
    DATE '2022-01-01',
    DATE '2026-12-31',
    INTERVAL '1 day'
) AS series(d);

-- Confirm the number of rows
SELECT COUNT(*) AS total_days
FROM dwh.dim_date;

--1. Date range check
SELECT
    COUNT(*) AS total_days,
    MIN(date_actual) AS first_date,
    MAX(date_actual) AS last_date
FROM dwh.dim_date;
