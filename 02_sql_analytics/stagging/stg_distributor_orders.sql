CREATE TABLE staging.stg_distributor_orders AS
WITH cleaned AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(order_date), '') AS order_date_raw,
        NULLIF(TRIM(order_month), '') AS order_month,
        NULLIF(TRIM(order_quarter), '') AS order_quarter,
        NULLIF(TRIM(distributor_id), '') AS distributor_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_category), '') AS product_category,
        NULLIF(TRIM(qty_ordered), '') AS qty_ordered_raw,
        NULLIF(TRIM(qty_delivered), '') AS qty_delivered_raw,
        NULLIF(TRIM(fill_rate_pct), '') AS fill_rate_pct_raw,
        NULLIF(TRIM(unit_price_list), '') AS unit_price_list_raw,
        NULLIF(TRIM(distributor_price), '') AS distributor_price_raw,
        NULLIF(TRIM(gross_amount), '') AS gross_amount_raw,
        NULLIF(TRIM(delivered_amount), '') AS delivered_amount_raw,
        NULLIF(TRIM(expected_delivery_date), '') AS expected_delivery_date_raw,
        NULLIF(TRIM(actual_delivery_date), '') AS actual_delivery_date_raw,
        NULLIF(TRIM(ontime_delivery), '') AS ontime_delivery,
        NULLIF(TRIM(delivery_status), '') AS delivery_status,
        NULLIF(TRIM(payment_terms), '') AS payment_terms,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM raw.distributor_orders
)
SELECT
    order_id,
    CASE
        WHEN order_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN order_date_raw::DATE
        ELSE NULL
    END AS order_date,
    order_month,
    order_quarter,
    distributor_id,
    region,
    channel,
    product_id,
    product_category,
    CASE
        WHEN qty_ordered_raw ~ '^[+-]?\d+$'
        THEN qty_ordered_raw::INTEGER
        ELSE NULL
    END AS qty_ordered,
    CASE
        WHEN qty_delivered_raw ~ '^[+-]?\d+$'
        THEN qty_delivered_raw::INTEGER
        ELSE NULL
    END AS qty_delivered,
    CASE
        WHEN fill_rate_pct_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN fill_rate_pct_raw::NUMERIC
        ELSE NULL
    END AS fill_rate_pct,
    CASE
        WHEN unit_price_list_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN unit_price_list_raw::NUMERIC
        ELSE NULL
    END AS unit_price_list,
    CASE
        WHEN distributor_price_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN distributor_price_raw::NUMERIC
        ELSE NULL
    END AS distributor_price,
    CASE
        WHEN gross_amount_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN gross_amount_raw::NUMERIC
        ELSE NULL
    END AS gross_amount,
    CASE
        WHEN delivered_amount_raw ~ '^[+-]?\d+(\.\d+)?$'
        THEN delivered_amount_raw::NUMERIC
        ELSE NULL
    END AS delivered_amount,
    CASE
        WHEN expected_delivery_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN expected_delivery_date_raw::DATE
        ELSE NULL
    END AS expected_delivery_date,
    CASE
        WHEN actual_delivery_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
        THEN actual_delivery_date_raw::DATE
        ELSE NULL
    END AS actual_delivery_date,
    ontime_delivery,
    delivery_status,
    payment_terms,
    _source_file,
    _source_platform,
    _ingested_at,
    _batch_id
FROM cleaned;

--1. Row count comparison between raw and staging tables
SELECT 'distributor_orders' AS table_name,
       (SELECT COUNT(*) FROM raw.distributor_orders) AS bronze_rows,
       (SELECT COUNT(*) FROM staging.stg_distributor_orders) AS silver_rows

--2. Null-check
SELECT
    'stg_distributor_orders',
    COUNT(*) FILTER (WHERE order_date IS NULL),
    COUNT(*) FILTER (
        WHERE qty_ordered IS NULL
           OR qty_delivered IS NULL
           OR gross_amount IS NULL
           OR delivered_amount IS NULL
    )
FROM staging.stg_distributor_orders

--3. Quantity and amount validation
SELECT
    COUNT(*) FILTER (
        WHERE qty_ordered <= 0
    ) AS invalid_qty_ordered,

    COUNT(*) FILTER (
        WHERE qty_delivered < 0
    ) AS negative_qty_delivered,

    COUNT(*) FILTER (
        WHERE qty_delivered > qty_ordered
    ) AS delivered_over_ordered,

    COUNT(*) FILTER (
        WHERE fill_rate_pct < 0
           OR fill_rate_pct > 100
    ) AS invalid_fill_rate,

    COUNT(*) FILTER (
        WHERE unit_price_list < 0
           OR distributor_price < 0
           OR gross_amount < 0
           OR delivered_amount < 0
    ) AS negative_amounts

FROM staging.stg_distributor_orders;

--4. Delivery date validation
SELECT
    COUNT(*) FILTER (
        WHERE expected_delivery_date IS NOT NULL
          AND order_date IS NOT NULL
          AND expected_delivery_date < order_date
    ) AS expected_before_order,

    COUNT(*) FILTER (
        WHERE actual_delivery_date IS NOT NULL
          AND order_date IS NOT NULL
          AND actual_delivery_date < order_date
    ) AS actual_before_order,

    COUNT(*) FILTER (
        WHERE actual_delivery_date IS NOT NULL
          AND expected_delivery_date IS NOT NULL
          AND actual_delivery_date > expected_delivery_date
    ) AS delivered_late

FROM staging.stg_distributor_orders;

-- 5. distributor_id does not exist in stg_distributors
SELECT
    COUNT(*) AS orphan_distributor_count
FROM staging.stg_distributor_orders o
WHERE o.distributor_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.stg_distributors d
      WHERE d.distributor_id = o.distributor_id
  );

-- 6. product_id does not exist in stg_products
SELECT
    COUNT(*) AS orphan_product_count
FROM staging.stg_distributor_orders o
WHERE o.product_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.stg_products p
      WHERE p.product_id = o.product_id
  );