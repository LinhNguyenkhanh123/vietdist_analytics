CREATE TABLE dwh.fact_sales (
    sales_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_id TEXT NOT NULL,
    date_key INTEGER NOT NULL,
    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    employee_key BIGINT NOT NULL,
    quantity INTEGER,
    unit_price NUMERIC,
    discount_pct NUMERIC,
    discount_amount NUMERIC,
    gross_amount NUMERIC,
    net_amount NUMERIC,
    region TEXT,
    province TEXT,
    channel TEXT,
    product_category TEXT,
    delivery_status TEXT,
    payment_method TEXT,
    payment_status TEXT,

    CONSTRAINT fk_fact_sales_date
        FOREIGN KEY (date_key)
        REFERENCES dwh.dim_date(date_key),
        
    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_key)
        REFERENCES dwh.dim_customers(customer_key),

    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_key)
        REFERENCES dwh.dim_products(product_key),

    CONSTRAINT fk_fact_sales_employee
        FOREIGN KEY (employee_key)
        REFERENCES dwh.dim_employees(employee_key)
);

-- Load sales line items
INSERT INTO dwh.fact_sales (
    order_id,
    date_key,
    customer_key,
    product_key,
    employee_key,
    quantity,
    unit_price,
    discount_pct,
    discount_amount,
    gross_amount,
    net_amount,
    region,
    province,
    channel,
    product_category,
    delivery_status,
    payment_method,
    payment_status
)
SELECT
    s.order_id,
    d.date_key,
    c.customer_key,
    p.product_key,
    e.employee_key,
    s.quantity,
    s.unit_price,
    s.discount_pct,
    s.discount_amount,
    s.gross_amount,
    s.net_amount,
    s.region,
    s.province,
    s.channel,
    s.product_category,
    s.delivery_status,
    s.payment_method,
    s.payment_status
FROM staging.stg_sales_transactions s
JOIN dwh.dim_date d
    ON s.order_date = d.date_actual
JOIN dwh.dim_customers c
    ON TRIM(s.customer_id) = c.customer_id
JOIN dwh.dim_products p
    ON TRIM(s.product_id) = p.product_id
JOIN dwh.dim_employees e
    ON TRIM(s.employee_id) = e.employee_id
   AND s.order_date >= e.effective_from
   AND s.order_date <= e.effective_to;
