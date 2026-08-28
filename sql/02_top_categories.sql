SELECT
    t.product_category_name_english AS category,
    ROUND(SUM(oi.price)::numeric, 2) AS revenue,
    COUNT(DISTINCT oi.order_id) AS orders
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr ON oi.product_id = pr.product_id
JOIN product_category_name_translation t ON pr.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;