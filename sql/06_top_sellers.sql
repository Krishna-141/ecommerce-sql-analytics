SELECT seller_id, total_revenue,
       RANK() OVER (ORDER BY total_revenue DESC) AS seller_rank
FROM (
    SELECT seller_id, ROUND(SUM(price)::numeric, 2) AS total_revenue
    FROM olist_order_items_dataset
    GROUP BY seller_id
) s
ORDER BY seller_rank
LIMIT 10;
