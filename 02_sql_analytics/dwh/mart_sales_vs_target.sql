CREATE TABLE dwh.mart_sales_vs_target AS
WITH sales_monthly AS (
    SELECT
        e.employee_id,
        DATE_TRUNC('month', d.date_actual)::DATE AS target_month,
        SUM(f.net_amount) AS actual_revenue,
        SUM(f.quantity) AS actual_quantity,
        COUNT(DISTINCT f.order_id) AS order_count
    FROM dwh.fact_sales f
    JOIN dwh.dim_date d
        ON f.date_key = d.date_key
    JOIN dwh.dim_employees e
        ON f.employee_key = e.employee_key
    GROUP BY
        e.employee_id,
        DATE_TRUNC('month', d.date_actual)::DATE
),

targets_monthly AS (
    SELECT
        e.employee_id,
        t.target_month,
        SUM(t.target_revenue) AS target_revenue,
        SUM(t.target_quantity) AS target_quantity,
        SUM(t.target_new_customers) AS target_new_customers
    FROM dwh.fact_targets t
    JOIN dwh.dim_employees e
        ON t.employee_key = e.employee_key
    WHERE t.is_latest = TRUE
    GROUP BY
        e.employee_id,
        t.target_month
),

combined AS (
    SELECT
        COALESCE(s.employee_id, t.employee_id) AS employee_id,
        COALESCE(s.target_month, t.target_month) AS target_month,

        s.actual_revenue,
        s.actual_quantity,
        s.order_count,

        t.target_revenue,
        t.target_quantity,
        t.target_new_customers
    FROM sales_monthly s
    FULL OUTER JOIN targets_monthly t
        ON s.employee_id = t.employee_id
       AND s.target_month = t.target_month
)

SELECT
    c.employee_id,
    c.target_month,

    c.actual_revenue,
    c.target_revenue,
    c.actual_revenue - c.target_revenue AS revenue_variance,

    ROUND(
        100.0 * c.actual_revenue
        / NULLIF(c.target_revenue, 0),
        2
    ) AS revenue_achievement_pct,

    c.actual_quantity,
    c.target_quantity,

    ROUND(
        100.0 * c.actual_quantity
        / NULLIF(c.target_quantity, 0),
        2
    ) AS quantity_achievement_pct,

    c.order_count,
    c.target_new_customers,

    CASE
        WHEN c.actual_revenue IS NULL THEN 'No sales'
        WHEN c.target_revenue IS NULL THEN 'No target'
        ELSE 'Sales and target'
    END AS comparison_status

FROM combined c;