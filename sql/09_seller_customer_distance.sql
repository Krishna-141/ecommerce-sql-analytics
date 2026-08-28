WITH geo_dedup AS (
    -- collapse duplicate lat/lng rows per zip prefix, drop out-of-Brazil errors
    SELECT
        geolocation_zip_code_prefix AS zip_prefix,
        AVG(geolocation_lat) AS lat,
        AVG(geolocation_lng) AS lng
    FROM olist_geolocation_dataset
    WHERE geolocation_lat BETWEEN -34 AND 5
      AND geolocation_lng BETWEEN -74 AND -34
    GROUP BY geolocation_zip_code_prefix
),
order_distance AS (
    SELECT
        o.order_id,
        o.order_purchase_timestamp ,
        o.order_delivered_customer_date,
        cg.lat AS cust_lat, cg.lng AS cust_lng,
        sg.lat AS seller_lat, sg.lng AS seller_lng
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    JOIN geo_dedup cg ON c.customer_zip_code_prefix = cg.zip_prefix
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    JOIN olist_sellers_dataset s ON oi.seller_id = s.seller_id
    JOIN geo_dedup sg ON s.seller_zip_code_prefix = sg.zip_prefix
    WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
),
distance_calc AS (
    SELECT DISTINCT
        order_id,
        EXTRACT(EPOCH FROM (order_delivered_customer_date::timestamp - order_purchase_timestamp::timestamp)) / 86400 AS delivery_days,
        6371 * acos(
            LEAST(1.0,
                cos(radians(cust_lat)) * cos(radians(seller_lat)) * cos(radians(seller_lng) - radians(cust_lng))
                + sin(radians(cust_lat)) * sin(radians(seller_lat))
            )
        ) AS distance_km
    FROM order_distance
)
SELECT
    WIDTH_BUCKET(distance_km, 0, 3000, 6) AS distance_bucket,
    ROUND(MIN(distance_km)::numeric, 0) AS min_km,
    ROUND(MAX(distance_km)::numeric, 0) AS max_km,
    COUNT(*) AS num_orders,
    ROUND(AVG(delivery_days)::numeric, 1) AS avg_delivery_days
FROM distance_calc
GROUP BY 1
ORDER BY 1;