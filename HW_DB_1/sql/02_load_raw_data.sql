-- HW_DB_1
-- Заливаем данные в таблицы для ДЗ_1

BEGIN;

-- Формируем таблицы
TRUNCATE TABLE
    raw.order_items,
    raw.orders,
    raw.products,
    raw.customers
RESTART IDENTITY;

COPY raw.customers (
    customer_id,
    first_name,
    last_name,
    gender,
    dob,
    job_title,
    job_industry_category,
    wealth_segment,
    deceased_indicator,
    owns_car,
    address,
    postcode,
    state,
    country,
    property_valuation
)
FROM '/workspace/HW_DB_1/data/raw/customers.csv'
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY raw.products (
    product_id,
    brand,
    product_line,
    product_class,
    product_size,
    list_price,
    standard_cost
)
FROM '/workspace/HW_DB_1/data/raw/products.csv'
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY raw.orders (
    order_id,
    customer_id,
    order_date,
    online_order,
    order_status
)
FROM '/workspace/HW_DB_1/data/raw/orders.csv'
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COPY raw.order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    item_list_price_at_sale,
    item_standard_cost_at_sale
)
FROM '/workspace/HW_DB_1/data/raw/order_items.csv'
WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

COMMIT;

-- Контроьные суммы для проверки:
-- customers   = 5000
-- products    = 300
-- orders      = 25000
-- order_items = 50000
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers
UNION ALL
SELECT 'products', COUNT(*)
FROM raw.products
UNION ALL
SELECT 'orders', COUNT(*)
FROM raw.orders
UNION ALL
SELECT 'order_items', COUNT(*)
FROM raw.order_items
ORDER BY table_name;
