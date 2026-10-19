CREATE TABLE dwh.mart_distributor_performance AS
WITH line_metrics AS (
    SELECT
        distributor_id,
        order_id,
        delivery_status,
        ontime_delivery,
        qty_ordered,
        qty_delivered,
        gross_amount,
        delivered_amount,
        expected_delivery_date,
        actual_delivery_date
    FROM staging.stg_distributor_orders
),

distributor_metrics AS (
    SELECT
        distributor_id,

        COUNT(DISTINCT order_id) AS total_orders,

        SUM(gross_amount) AS total_order_value,
        SUM(delivered_amount) AS total_delivered_value,

        SUM(qty_ordered) AS total_qty_ordered,
        SUM(qty_delivered) AS total_qty_delivered,

        COUNT(*) FILTER (
            WHERE delivery_status = 'Delivered'
        ) AS delivered_lines,

        COUNT(*) FILTER (
            WHERE delivery_status = 'Partial'
        ) AS partial_lines,

        COUNT(*) FILTER (
            WHERE delivery_status = 'Cancelled'
        ) AS cancelled_lines,

        COUNT(*) FILTER (
            WHERE delivery_status <> 'Cancelled'
              AND ontime_delivery = 'Yes'
        ) AS ontime_non_cancelled_lines,

        COUNT(*) FILTER (
            WHERE delivery_status <> 'Cancelled'
              AND ontime_delivery IN ('Yes', 'No')
        ) AS non_cancelled_lines_with_ontime_flag,

        COUNT(*) FILTER (
            WHERE delivery_status <> 'Cancelled'
              AND ontime_delivery = 'No'
        ) AS late_non_cancelled_lines

    FROM line_metrics
    GROUP BY distributor_id
),

order_metrics AS (
    SELECT
        distributor_id,
        order_id,

        BOOL_OR(
            delivery_status = 'Cancelled'
        ) AS has_cancelled_line,

        BOOL_AND(
            delivery_status = 'Delivered'
        ) AS all_lines_delivered,

        BOOL_OR(
            delivery_status = 'Partial'
        ) AS has_partial_line,

        BOOL_OR(
            delivery_status <> 'Cancelled'
            AND ontime_delivery = 'No'
        ) AS has_late_line

    FROM line_metrics
    GROUP BY distributor_id, order_id
),

distributor_order_metrics AS (
    SELECT
        distributor_id,

        COUNT(*) FILTER (
            WHERE all_lines_delivered
        ) AS fully_delivered_orders,

        COUNT(*) FILTER (
            WHERE has_partial_line
        ) AS orders_with_partial_lines,

        COUNT(*) FILTER (
            WHERE has_cancelled_line
        ) AS orders_with_cancelled_lines,

        COUNT(*) FILTER (
            WHERE has_late_line
        ) AS orders_with_late_lines

    FROM order_metrics
    GROUP BY distributor_id
)

SELECT
    d.distributor_key,
    d.distributor_id,
    d.distributor_name,
    d.tier,
    d.region,
    d.channel,

    m.total_orders,
    m.total_order_value,
    m.total_delivered_value,

    m.total_qty_ordered,
    m.total_qty_delivered,

    ROUND(
        100.0 * m.total_qty_delivered
        / NULLIF(m.total_qty_ordered, 0),
        2
    ) AS fill_rate_pct,

    om.fully_delivered_orders,
    om.orders_with_partial_lines,
    om.orders_with_cancelled_lines,
    om.orders_with_late_lines,

    ROUND(
        100.0 * om.fully_delivered_orders
        / NULLIF(m.total_orders, 0),
        2
    ) AS fully_delivered_order_pct,

    ROUND(
        100.0 * m.ontime_non_cancelled_lines
        / NULLIF(m.non_cancelled_lines_with_ontime_flag, 0),
        2
    ) AS ontime_line_pct,

    ROUND(
        100.0 * m.late_non_cancelled_lines
        / NULLIF(m.non_cancelled_lines_with_ontime_flag, 0),
        2
    ) AS late_line_pct,

    ROUND(
        100.0 * om.orders_with_late_lines
        / NULLIF(m.total_orders, 0),
        2
    ) AS orders_with_late_line_pct

FROM distributor_metrics m
JOIN distributor_order_metrics om
    ON m.distributor_id = om.distributor_id
JOIN dwh.dim_distributors d
    ON TRIM(m.distributor_id) = d.distributor_id
   AND d.is_current = TRUE;
