SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp::timestamp ) AS order_month,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;