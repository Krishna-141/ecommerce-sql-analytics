import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql://postgres:postgres@localhost:5432/olist")

files = {
    "olist_orders_dataset": "data/raw/olist_orders_dataset.csv",
    "olist_customers_dataset": "data/raw/olist_customers_dataset.csv",
    "olist_order_items_dataset": "data/raw/olist_order_items_dataset.csv",
    "olist_order_payments_dataset": "data/raw/olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset": "data/raw/olist_order_reviews_dataset.csv",
    "olist_products_dataset": "data/raw/olist_products_dataset.csv",
    "olist_sellers_dataset": "data/raw/olist_sellers_dataset.csv",
    "olist_geolocation_dataset": "data/raw/olist_geolocation_dataset.csv",
    "product_category_name_translation": "data/raw/product_category_name_translation.csv",
}

for table, path in files.items():
    df = pd.read_csv(path)
    df.to_sql(table, engine, if_exists="replace", index=False)
    print(f"Loaded {table}: {len(df)} rows")