CREATE TABLE staging.stg_sales_targets AS
WITH cleaned AS (
    SELECT
        target_row_id,
        target_file_id,
        source_row,
        NULLIF(TRIM(month_col), '') AS month_col,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id,
        NULLIF(TRIM(plan_version), '') AS plan_version,
        NULLIF(TRIM(version_date), '') AS version_date_raw,
        NULLIF(TRIM(effective_from), '') AS effective_from_raw,
        NULLIF(TRIM(effective_to), '') AS effective_to_raw,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(employee_name), '') AS employee_name,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(team), '') AS team,
        NULLIF(TRIM(year), '') AS year_raw,
        NULLIF(TRIM(month), '') AS month_raw,
        NULLIF(TRIM(target_revenue), '') AS target_revenue_raw,
        NULLIF(TRIM(target_quantity), '') AS target_quantity_raw,
        NULLIF(TRIM(target_new_customers), '') AS target_new_customers_raw
    FROM raw.sales_targets_raw
)
SELECT
    target_row_id,
    target_file_id,
    source_row,
    month_col,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id,
    plan_version,
    CASE
        WHEN version_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN version_date_raw::DATE
        ELSE NULL
    END AS version_date,
    CASE
        WHEN effective_from_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN effective_from_raw::DATE
        ELSE NULL
    END AS effective_from,
    CASE
        WHEN effective_to_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN effective_to_raw::DATE
        ELSE NULL
    END AS effective_to,
    employee_id,
    employee_name,
    region,
    team,
    CASE
        WHEN year_raw ~ '^\d{4}$'
        THEN year_raw::INTEGER
        ELSE NULL
    END AS year,
    CASE
        WHEN month_raw ~ '^\d{1,2}$'
        THEN month_raw::INTEGER
        ELSE NULL
    END AS month,
    CASE
        WHEN target_revenue_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN target_revenue_raw::NUMERIC
        ELSE NULL
    END AS target_revenue,
    CASE
        WHEN target_quantity_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN target_quantity_raw::NUMERIC
        ELSE NULL
    END AS target_quantity,
    CASE
        WHEN target_new_customers_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN target_new_customers_raw::NUMERIC
        ELSE NULL
    END AS target_new_customers
FROM cleaned;

--1. Row count comparison between raw and staging tables
SELECT 'sales_targets',
       (SELECT COUNT(*) FROM raw.sales_targets_raw),
       (SELECT COUNT(*) FROM staging.stg_sales_targets);

--2. Null-check
SELECT
    'stg_sales_targets',
    COUNT(*) FILTER (WHERE version_date IS NULL),
    COUNT(*) FILTER (
        WHERE target_revenue IS NULL
           OR target_quantity IS NULL
           OR target_new_customers IS NULL
    )
FROM staging.stg_sales_targets

--3. employee_id validation

SELECT
    COUNT(*) AS orphan_employee_count
FROM staging.stg_sales_targets t
WHERE t.employee_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.stg_employees e
      WHERE e.employee_id = t.employee_id
  );

--4. Quantity and amount validation
SELECT
    COUNT(*) FILTER (
        WHERE year IS NULL
           OR month IS NULL
           OR month < 1
           OR month > 12
    ) AS invalid_period,

    COUNT(*) FILTER (
        WHERE target_revenue < 0
    ) AS negative_target_revenue,

    COUNT(*) FILTER (
        WHERE target_quantity < 0
    ) AS negative_target_quantity,

    COUNT(*) FILTER (
        WHERE target_new_customers < 0
    ) AS negative_target_new_customers,

    COUNT(*) FILTER (
        WHERE effective_from IS NOT NULL
          AND effective_to IS NOT NULL
          AND effective_from > effective_to
    ) AS invalid_effective_period

FROM staging.stg_sales_targets;

--5. Summary for each plan_version and time
SELECT
    plan_version,
    year,
    month,
    COUNT(*) AS row_count,
    COUNT(DISTINCT employee_id) AS employee_count
FROM staging.stg_sales_targets
GROUP BY plan_version, year, month
ORDER BY year, month, plan_version;

--6. Check for duplicates based on plan_version, year, month, and employee_id
SELECT
    plan_version,
    year,
    month,
    employee_id,
    COUNT(*) AS record_count
FROM staging.stg_sales_targets
GROUP BY
    plan_version,
    year,
    month,
    employee_id
HAVING COUNT(*) > 1
ORDER BY
    year, month, employee_id, plan_version;

