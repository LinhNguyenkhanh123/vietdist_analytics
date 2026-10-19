CREATE TABLE staging.stg_sales_transactions AS
WITH cleaned AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(order_date), '') AS order_date_raw,
        NULLIF(TRIM(order_month), '') AS order_month,
        NULLIF(TRIM(order_quarter), '') AS order_quarter,
        NULLIF(TRIM(order_year), '') AS order_year_raw,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(region), '') AS region,
        NULLIF(TRIM(province), '') AS province,
        NULLIF(TRIM(channel), '') AS channel,
        NULLIF(TRIM(employee_id), '') AS employee_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_category), '') AS product_category,
        NULLIF(TRIM(quantity), '') AS quantity_raw,
        NULLIF(TRIM(unit_price), '') AS unit_price_raw,
        NULLIF(TRIM(discount_pct), '') AS discount_pct_raw,
        NULLIF(TRIM(discount_amount), '') AS discount_amount_raw,
        NULLIF(TRIM(gross_amount), '') AS gross_amount_raw,
        NULLIF(TRIM(net_amount), '') AS net_amount_raw,
        NULLIF(TRIM(delivery_status), '') AS delivery_status,
        NULLIF(TRIM(payment_method), '') AS payment_method,
        NULLIF(TRIM(payment_status), '') AS payment_status,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM raw.sales_transactions
),
typed AS (
    SELECT
        order_id,

        CASE
            WHEN order_date_raw ~ '^\d{4}-\d{2}-\d{2}$'
            THEN order_date_raw::DATE
            ELSE NULL
        END AS order_date,
        order_month,
        order_quarter,

        CASE
            WHEN order_year_raw ~ '^\d{4}$'
            THEN order_year_raw::INTEGER
            ELSE NULL
        END AS order_year,
        customer_id,
        region,
        province,
        channel,
        employee_id,
        product_id,
        product_category,

        CASE
            WHEN quantity_raw ~ '^[+-]?\d+$'
            THEN quantity_raw::INTEGER
            ELSE NULL
        END AS quantity,

        CASE
            WHEN unit_price_raw ~ '^[+-]?\d+(\.\d+)?$'
            THEN unit_price_raw::NUMERIC
            ELSE NULL
        END AS unit_price,

        CASE
            WHEN discount_pct_raw ~ '^[+-]?\d+(\.\d+)?$'
            THEN discount_pct_raw::NUMERIC
            ELSE NULL
        END AS discount_pct,

        CASE
            WHEN discount_amount_raw ~ '^[+-]?\d+(\.\d+)?$'
            THEN discount_amount_raw::NUMERIC
            ELSE NULL
        END AS discount_amount,

        CASE
            WHEN gross_amount_raw ~ '^[+-]?\d+(\.\d+)?$'
            THEN gross_amount_raw::NUMERIC
            ELSE NULL
        END AS gross_amount,

        CASE
            WHEN net_amount_raw ~ '^[+-]?\d+(\.\d+)?$'
            THEN net_amount_raw::NUMERIC
            ELSE NULL
        END AS net_amount,
        delivery_status,
        payment_method,
        payment_status,
        _source_file,
        _source_platform,
        _ingested_at,
        _batch_id
    FROM cleaned
)
SELECT *
FROM typed;


-- 1. Row comparison between raw and staging tables
SELECT
    (SELECT COUNT(*) FROM raw.sales_transactions) AS bronze_rows,
    (SELECT COUNT(*) FROM staging.stg_sales_transactions) AS silver_rows;

-- 2. Data type check
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
  AND table_name = 'stg_sales_transactions'
ORDER BY ordinal_position;

-- 3. Null-check
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS null_unit_price,
    COUNT(*) FILTER (WHERE discount_pct IS NULL) AS null_discount_pct,
    COUNT(*) FILTER (WHERE gross_amount IS NULL) AS null_gross_amount,
    COUNT(*) FILTER (WHERE net_amount IS NULL) AS null_net_amount
FROM staging.stg_sales_transactions;

-- 4. Quantity and price validation
SELECT
    COUNT(*) FILTER (WHERE quantity <= 0) AS invalid_quantity,
    COUNT(*) FILTER (WHERE unit_price < 0) AS negative_unit_price,
    COUNT(*) FILTER (
        WHERE discount_pct < 0 OR discount_pct > 100
    ) AS invalid_discount_pct,
    COUNT(*) FILTER (WHERE discount_amount < 0) AS negative_discount,
    COUNT(*) FILTER (WHERE gross_amount < 0) AS negative_gross_amount,
    COUNT(*) FILTER (WHERE net_amount < 0) AS negative_net_amount
FROM staging.stg_sales_transactions;

-- 5. Order date consistency check
SELECT
    COUNT(*) FILTER (
        WHERE EXTRACT(YEAR FROM order_date) <> order_year
    ) AS inconsistent_order_year,
    MIN(order_date) AS earliest_order_date,
    MAX(order_date) AS latest_order_date
FROM staging.stg_sales_transactions;

-- 6. customer_id does not exist in customer master
SELECT COUNT(*) AS orphan_customer_count
FROM staging.stg_sales_transactions s
WHERE s.customer_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.stg_customers c
      WHERE c.customer_id = s.customer_id
  );

-- 7. product_id does not exist in product master
SELECT COUNT(*) AS orphan_product_count
FROM staging.stg_sales_transactions s
WHERE s.product_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.stg_products p
      WHERE p.product_id = s.product_id
  );

-- 8. employee_id does not exist in employee master
SELECT COUNT(*) AS orphan_employee_count
FROM staging.stg_sales_transactions s
WHERE s.employee_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.stg_employees e
      WHERE e.employee_id = s.employee_id
  );