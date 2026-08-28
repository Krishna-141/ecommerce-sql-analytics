# Data Quality Audit

Before writing any analytical query, I ran a structured audit against the raw Olist tables to check the assumptions the rest of the project relies on — join integrity, null rates on key columns, and coordinate validity in the geolocation table. Below is what I found and how I handled each issue.

## 1. Missing delivery dates

```sql
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_date,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)
        / COUNT(*), 1) AS pct_null_delivered
FROM olist_orders_dataset;
```

**Result:** 99,441 total orders. 2,965 (3.0%) are missing `order_delivered_customer_date`; a much smaller 160 are missing `order_approved_at`.

**Decision:** Excluded the 2,965 rows from all delivery-time calculations rather than imputing a value. Imputing (e.g. filling with the average delivery time) would have artificially smoothed out exactly the tail-end delays the analysis is trying to measure, biasing the late-delivery findings toward whatever assumption I picked. These are almost certainly orders that were cancelled, still in transit, or never confirmed as delivered — not a data entry error — so exclusion is the honest choice, not a workaround.

## 2. Orphaned foreign keys

```sql
SELECT COUNT(*) AS orphaned_product_refs
FROM olist_order_items_dataset oi
LEFT JOIN olist_products_dataset pr ON oi.product_id = pr.product_id
WHERE pr.product_id IS NULL;
```

**Result:** 0 orphaned references — every `product_id` in `order_items` has a matching row in `products`.

**Decision:** No cleanup needed. This confirms the `order_items → products` join used throughout the project (top categories, RFM, seller rankings) is safe to rely on without a defensive `LEFT JOIN` or null-check.

## 3. Categories missing an English translation

```sql
SELECT DISTINCT pr.product_category_name
FROM olist_products_dataset pr
LEFT JOIN product_category_name_translation t
    ON pr.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL;
```

**Result:** 2 categories have no matching row in the translation table: `portateis_cozinha_e_preparadores_de_alimentos` and `pc_gamer`.

**Decision:** Grouped both under `'other'` in category-level reporting (Top 10 Categories tile, revenue-by-category queries) instead of dropping the rows outright. Dropping them would silently understate total revenue every time a category-level `JOIN` or `GROUP BY` ran — a small but avoidable accuracy loss.

## 4. Geolocation duplicates

```sql
SELECT geolocation_zip_code_prefix, COUNT(*) AS num_rows
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix
ORDER BY num_rows DESC
LIMIT 5;
```

**Result:** Multiple lat/lng rows exist per zip-code prefix, with the worst case (a single prefix) carrying 1,146 duplicate rows.

**Decision:** Before using this table for the seller-customer distance calculation (query 9), collapsed it to one row per zip-code prefix by averaging `geolocation_lat`/`geolocation_lng` within each prefix. A raw, un-deduplicated join would have fanned out order rows and silently inflated both order counts and distance averages in the Haversine calculation.

## 5. Out-of-bounds coordinates

```sql
SELECT COUNT(*) AS out_of_bounds_points
FROM olist_geolocation_dataset
WHERE geolocation_lat > 5 OR geolocation_lat < -34
   OR geolocation_lng > -34 OR geolocation_lng < -74;
```

**Result:** 42 rows have coordinates falling outside Brazil's approximate bounding box (latitude −34 to 5, longitude −74 to −34) — almost certainly geocoding errors rather than real locations.

**Decision:** Excluded these 42 rows before deduplicating and joining the geolocation table (see #4), so they can't distort the seller-customer distance buckets or the average-delivery-time-by-distance findings.

---

**Net effect on the analysis:** delivery-time metrics are based only on confirmed-delivered orders (Finding #1), category-level revenue totals stay complete rather than undercounted (Finding #3), and the distance-based delivery analysis (Tile 4 of the dashboard) is built on a cleaned, deduplicated, geographically valid version of the geolocation table (Findings #4–5). The `order_items → products` join required no cleanup at all (Finding #2).
