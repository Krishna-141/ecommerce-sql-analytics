WITH first_purchase AS (
    SELECT c.customer_unique_id,
           DATE_TRUNC('month', MIN(o.order_purchase_timestamp::timestamp )) AS cohort_month
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
orders_with_cohort AS (
    SELECT c.customer_unique_id, fp.cohort_month,
           DATE_TRUNC('month', o.order_purchase_timestamp::timestamp ) AS order_month
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    JOIN first_purchase fp ON c.customer_unique_id = fp.customer_unique_id
)
SELECT
    cohort_month,
    (EXTRACT(YEAR FROM AGE(order_month, cohort_month)) * 12
     + EXTRACT(MONTH FROM AGE(order_month, cohort_month))) AS month_offset,
    COUNT(DISTINCT customer_unique_id) AS active_customers
FROM orders_with_cohort
GROUP BY 1, 2
ORDER BY 1, 2;
