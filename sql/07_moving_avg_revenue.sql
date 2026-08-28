SELECT order_date, daily_revenue,
       ROUND(AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)::numeric, 2) AS revenue_7day_avg
FROM (
    SELECT DATE(o.order_purchase_timestamp) AS order_date, SUM(p.payment_value) AS daily_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    GROUP BY 1
) daily
ORDER BY order_date;