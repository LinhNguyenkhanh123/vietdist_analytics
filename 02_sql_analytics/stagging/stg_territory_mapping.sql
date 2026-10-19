
DROP TABLE IF EXISTS staging.stg_territory_mapping;

CREATE TABLE staging.stg_territory_mapping AS
WITH cleaned AS (
    SELECT
        NULLIF(TRIM(territory_id), '') AS territory_id,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(team), '') AS team,
        NULLIF(TRIM(effective_date), '') AS effective_date_raw,
        NULLIF(TRIM(expiry_date), '') AS expiry_date_raw,
        NULLIF(TRIM(version), '') AS version,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM raw.territory_mapping
)
SELECT
    territory_id,
    employee_id,
    customer_id,
    region,
    team,
    CASE
        WHEN effective_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN effective_date_raw::DATE
        ELSE NULL
    END AS effective_date,
    CASE
        WHEN expiry_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN expiry_date_raw::DATE
        ELSE NULL
    END AS expiry_date,
    version,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM cleaned;

--1. Row count comparison between raw and staging tables
SELECT 'territory_mapping',
       (SELECT COUNT(*) FROM raw.territory_mapping),
       (SELECT COUNT(*) FROM staging.stg_territory_mapping)

--2. Null-check
SELECT
    'stg_territory_mapping',
    COUNT(*) FILTER (WHERE effective_date IS NULL),
    COUNT(*) FILTER (WHERE expiry_date IS NULL)
FROM staging.stg_territory_mapping

--3. Referential integrity checks
SELECT
    COUNT(*) FILTER (
        WHERE employee_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM staging.stg_employees e
              WHERE e.employee_id =
                    staging.stg_territory_mapping.employee_id
          )
    ) AS orphan_employee_count,

    COUNT(*) FILTER (
        WHERE customer_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM staging.stg_customers c
              WHERE c.customer_id =
                    staging.stg_territory_mapping.customer_id
          )
    ) AS orphan_customer_count,

    COUNT(*) FILTER (
        WHERE territory_id IS NULL
           OR TRIM(territory_id) = ''
    ) AS missing_territory_id_count,

    COUNT(*) FILTER (
        WHERE employee_id IS NULL
           OR TRIM(employee_id) = ''
    ) AS missing_employee_id_count,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
           OR TRIM(customer_id) = ''
    ) AS missing_customer_id_count

FROM staging.stg_territory_mapping;