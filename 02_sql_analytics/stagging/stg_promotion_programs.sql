
DROP TABLE IF EXISTS staging.stg_promotion_programs;

CREATE TABLE staging.stg_promotion_programs AS
WITH cleaned AS (
    SELECT
        NULLIF(TRIM(promotion_id), '') AS promotion_id,
        NULLIF(TRIM(promotion_name), '') AS promotion_name,
        NULLIF(TRIM(promotion_type), '') AS promotion_type,
        NULLIF(TRIM(target_channel), '') AS target_channel,
        NULLIF(TRIM(target_region), '') AS target_region,
        NULLIF(TRIM(start_date), '') AS start_date_raw,
        NULLIF(TRIM(end_date), '') AS end_date_raw,
        NULLIF(TRIM(applicable_products), '') AS applicable_products,
        NULLIF(TRIM(discount_pct), '') AS discount_pct_raw,
        NULLIF(TRIM(min_order_quantity), '') AS min_order_quantity_raw,
        NULLIF(TRIM(budget_vnd), '') AS budget_vnd_raw,
        NULLIF(TRIM(actual_cost_vnd), '') AS actual_cost_vnd_raw,
        NULLIF(TRIM(status), '') AS status,
        NULLIF(TRIM(created_by), '') AS created_by,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM raw.promotion_program
)
SELECT
    promotion_id,
    promotion_name,
    promotion_type,
    target_channel,
    target_region,
    CASE
        WHEN start_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN start_date_raw::DATE
        ELSE NULL
    END AS start_date,
    CASE
        WHEN end_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN end_date_raw::DATE
        ELSE NULL
    END AS end_date,
    applicable_products,
    CASE
        WHEN discount_pct_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN discount_pct_raw::NUMERIC
        ELSE NULL
    END AS discount_pct,
    CASE
        WHEN min_order_quantity_raw ~ '^[+-]?\d+$'
        THEN min_order_quantity_raw::INTEGER
        ELSE NULL
    END AS min_order_quantity,
    CASE
        WHEN budget_vnd_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN budget_vnd_raw::NUMERIC
        ELSE NULL
    END AS budget_vnd,
    CASE
        WHEN actual_cost_vnd_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN actual_cost_vnd_raw::NUMERIC
        ELSE NULL
    END AS actual_cost_vnd,
    status,
    created_by,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM cleaned;

--1. Row count comparison between raw and staging tables
SELECT 'promotion_programs',
       (SELECT COUNT(*) FROM raw.promotion_program),
       (SELECT COUNT(*) FROM staging.stg_promotion_programs);

--2. Null-check
SELECT
    'stg_promotion_programs',
    COUNT(*) FILTER (WHERE start_date IS NULL),
    COUNT(*) FILTER (
        WHERE discount_pct IS NULL
           OR budget_vnd IS NULL
           OR actual_cost_vnd IS NULL
    )
FROM staging.stg_promotion_programs;

--3. Quantity and amount validation
SELECT
    COUNT(*) FILTER (
        WHERE discount_pct < 0
           OR discount_pct > 100
    ) AS invalid_discount_pct,

    COUNT(*) FILTER (
        WHERE budget_vnd < 0
    ) AS negative_budget,

    COUNT(*) FILTER (
        WHERE actual_cost_vnd < 0
    ) AS negative_actual_cost,

    COUNT(*) FILTER (
        WHERE min_order_quantity < 0
    ) AS invalid_min_order_quantity,

    COUNT(*) FILTER (
        WHERE start_date > end_date
    ) AS invalid_date_range

FROM staging.stg_promotion_programs;
