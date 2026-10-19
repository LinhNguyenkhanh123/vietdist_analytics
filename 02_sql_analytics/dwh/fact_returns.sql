CREATE TABLE dwh.fact_returns (
    return_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    return_id TEXT NOT NULL UNIQUE,
    original_order_id TEXT NOT NULL,

    return_date_key INTEGER NOT NULL,
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    employee_key BIGINT NOT NULL,

    return_quantity INTEGER,
    unit_price NUMERIC,
    return_amount NUMERIC,

    region TEXT,
    province TEXT,
    return_reason TEXT,
    status TEXT,

    CONSTRAINT fk_fact_returns_date
        FOREIGN KEY (return_date_key)
        REFERENCES dwh.dim_date(date_key),

    CONSTRAINT fk_fact_returns_customer
        FOREIGN KEY (customer_key)
        REFERENCES dwh.dim_customers(customer_key),

    CONSTRAINT fk_fact_returns_product
        FOREIGN KEY (product_key)
        REFERENCES dwh.dim_products(product_key),

    CONSTRAINT fk_fact_returns_employee
        FOREIGN KEY (employee_key)
        REFERENCES dwh.dim_employees(employee_key)
);

-- Load return transactions
INSERT INTO dwh.fact_returns (
    return_id,
    original_order_id,
    return_date_key,
    customer_key,
    product_key,
    employee_key,
    return_quantity,
    unit_price,
    return_amount,
    region,
    province,
    return_reason,
    status
)
SELECT
    r.return_id,
    r.original_order_id,
    d.date_key,
    c.customer_key,
    p.product_key,
    e.employee_key,
    r.return_quantity,
    r.unit_price,
    r.return_amount,
    r.region,
    r.province,
    r.return_reason,
    r.status
FROM staging.stg_return_transactions r
JOIN dwh.dim_date d
    ON r.return_date = d.date_actual
JOIN dwh.dim_customers c
    ON TRIM(r.customer_id) = c.customer_id
JOIN dwh.dim_products p
    ON TRIM(r.product_id) = p.product_id
JOIN dwh.dim_employees e
    ON TRIM(r.employee_id) = e.employee_id
   AND r.return_date >= e.effective_from
   AND r.return_date <= e.effective_to;