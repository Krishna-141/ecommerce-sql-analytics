SELECT
    CASE WHEN order_delivered_customer_date::timestamp  > order_estimated_delivery_date::timestamp 
         THEN 'late' ELSE 'on_time_or_early' END AS delivery_status,
    COUNT(*) AS num_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date::timestamp  - order_purchase_timestamp::timestamp )) / 86400)::numeric, 1) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NOT NULL
GROUP BY 1;