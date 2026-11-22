-- HW_DB_1
-- Раскатываем таблицы из ДЗ_1, все поля текстовые
-- Работаем c подключением к hw_db_1


CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.customers (
    source_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id TEXT,
    first_name TEXT,
    last_name TEXT,
    gender TEXT,
    dob TEXT,
    job_title TEXT,
    job_industry_category TEXT,
    wealth_segment TEXT,
    deceased_indicator TEXT,
    owns_car TEXT,
    address TEXT,
    postcode TEXT,
    state TEXT,
    country TEXT,
    property_valuation TEXT
);

CREATE TABLE IF NOT EXISTS raw.products (
    source_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id TEXT,
    brand TEXT,
    product_line TEXT,
    product_class TEXT,
    product_size TEXT,
    list_price TEXT,
    standard_cost TEXT
);

CREATE TABLE IF NOT EXISTS raw.orders (
    source_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id TEXT,
    customer_id TEXT,
    order_date TEXT,
    online_order TEXT,
    order_status TEXT
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    source_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_item_id TEXT,
    order_id TEXT,
    product_id TEXT,
    quantity TEXT,
    item_list_price_at_sale TEXT,
    item_standard_cost_at_sale TEXT
);
