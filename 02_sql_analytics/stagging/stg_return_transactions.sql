
DROP TABLE IF EXISTS staging.stg_return_transactions;

CREATE TABLE staging.stg_return_transactions AS
WITH cleaned AS (
    SELECT
        NULLIF(TRIM(return_id), '') AS return_id,
        NULLIF(TRIM(original_order_id), '') AS original_order_id,
        NULLIF(TRIM(return_date), '') AS return_date_raw,
        NULLIF(TRIM(return_month), '') AS return_month,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(province), '') AS province,
        NULLIF(TRIM(return_quantity), '') AS return_quantity_raw,
        NULLIF(TRIM(unit_price), '') AS unit_price_raw,
        NULLIF(TRIM(return_amount), '') AS return_amount_raw,
        NULLIF(TRIM(return_reason), '') AS return_reason,
        NULLIF(TRIM(status), '') AS status,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM raw.return_transactions
)
SELECT
    return_id,
    original_order_id,
    CASE
        WHEN return_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN return_date_raw::DATE
        ELSE NULL
    END AS return_date,
    return_month,
    customer_id,
    employee_id,
    product_id,
    region,
    province,
    CASE
        WHEN return_quantity_raw ~ '^[+-]?\d+$'
        THEN return_quantity_raw::INTEGER
        ELSE NULL
    END AS return_quantity,
    CASE
        WHEN unit_price_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN unit_price_raw::NUMERIC
        ELSE NULL
    END AS unit_price,
    CASE
        WHEN return_amount_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN return_amount_raw::NUMERIC
        ELSE NULL
    END AS return_amount,
    return_reason,
    status,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM cleaned;

--1. Row count comparison between raw and staging tables
SELECT 'return_transactions',
       (SELECT COUNT(*) FROM raw.return_transactions),
       (SELECT COUNT(*) FROM staging.stg_return_transactions)

--2. Null-check
SELECT
    'stg_return_transactions',
    COUNT(*) FILTER (WHERE return_date IS NULL),
    COUNT(*) FILTER (
        WHERE return_quantity IS NULL
           OR return_amount IS NULL
    )
FROM staging.stg_return_transactions

--3. Quantity and amount validation
SELECT
    COUNT(*) FILTER (
        WHERE return_quantity <= 0
    ) AS invalid_return_quantity,

    COUNT(*) FILTER (
        WHERE unit_price < 0
    ) AS negative_unit_price,

    COUNT(*) FILTER (
        WHERE return_amount < 0
    ) AS negative_return_amount,

    COUNT(*) FILTER (
        WHERE return_date > CURRENT_DATE
    ) AS future_return_date,

    COUNT(*) FILTER (
        WHERE return_amount IS NOT NULL
          AND return_quantity IS NOT NULL
          AND unit_price IS NOT NULL
          AND ABS(
              return_amount - return_quantity * unit_price
          ) > 1
    ) AS amount_mismatches

FROM staging.stg_return_transactions;

--4. Referential integrity checks
SELECT
    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.stg_sales_transactions s
            WHERE s.order_id = r.original_order_id
        )
    ) AS orphan_order_count,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.stg_sales_transactions s
            WHERE s.order_id = r.original_order_id
              AND s.product_id = r.product_id
        )
    ) AS unmatched_order_product_count,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.stg_customers c
            WHERE c.customer_id = r.customer_id
        )
    ) AS orphan_customer_count,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.stg_employees e
            WHERE e.employee_id = r.employee_id
        )
    ) AS orphan_employee_count,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.stg_products p
            WHERE p.product_id = r.product_id
        )
    ) AS orphan_product_count

FROM staging.stg_return_transactions r;