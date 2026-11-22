-- HW_DB_1
-- Преобразуем исходный слой raw в типизированный слой core
-- Для каждого бизнес-ключа сохраняется первая исходная строка
-- Запускаем после 03_create_core_tables.sql (в коммит пойдут 03, 04 и 05 (далее) вместе)

BEGIN;

TRUNCATE TABLE
    core.order_items,
    core.orders,
    core.customers,
    core.products,
    core.locations
RESTART IDENTITY CASCADE;

-- Уникальные сочетания географических атрибутов
INSERT INTO core.locations (
    postcode,
    state,
    country
)
SELECT DISTINCT
    btrim(postcode),
    btrim(state),
    btrim(country)
FROM raw.customers
ORDER BY
    btrim(postcode),
    btrim(state),
    btrim(country);

-- Клиенты: преобразование типов и исключение повторов по customer_id
WITH ranked_customers AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY btrim(c.customer_id)::INTEGER
            ORDER BY c.source_row_id
        ) AS duplicate_rank
    FROM raw.customers AS c
)
INSERT INTO core.customers (
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
    location_id,
    property_valuation
)
SELECT
    btrim(c.customer_id)::INTEGER,
    btrim(c.first_name),
    btrim(c.last_name),
    btrim(c.gender),
    btrim(c.dob)::DATE,
    btrim(c.job_title),
    btrim(c.job_industry_category),
    btrim(c.wealth_segment),
    btrim(c.deceased_indicator)::BOOLEAN,
    btrim(c.owns_car)::BOOLEAN,
    btrim(c.address),
    l.location_id,
    btrim(c.property_valuation)::NUMERIC(5, 2)
FROM ranked_customers AS c
JOIN core.locations AS l
    ON l.postcode = btrim(c.postcode)
   AND l.state = btrim(c.state)
   AND l.country = btrim(c.country)
WHERE c.duplicate_rank = 1;

-- Продукты: преобразование типов и исключение повторов по product_id
WITH ranked_products AS (
    SELECT
        p.*,
        ROW_NUMBER() OVER (
            PARTITION BY btrim(p.product_id)::INTEGER
            ORDER BY p.source_row_id
        ) AS duplicate_rank
    FROM raw.products AS p
)
INSERT INTO core.products (
    product_id,
    brand,
    product_line,
    product_class,
    product_size,
    list_price,
    standard_cost
)
SELECT
    btrim(product_id)::INTEGER,
    btrim(brand),
    btrim(product_line),
    btrim(product_class),
    btrim(product_size),
    btrim(list_price)::NUMERIC(12, 2),
    btrim(standard_cost)::NUMERIC(12, 2)
FROM ranked_products
WHERE duplicate_rank = 1;

-- Заказы: преобразование типов и исключение повторов по order_id
WITH ranked_orders AS (
    SELECT
        o.*,
        ROW_NUMBER() OVER (
            PARTITION BY btrim(o.order_id)::INTEGER
            ORDER BY o.source_row_id
        ) AS duplicate_rank
    FROM raw.orders AS o
)
INSERT INTO core.orders (
    order_id,
    customer_id,
    order_date,
    online_order,
    order_status
)
SELECT
    btrim(order_id)::INTEGER,
    btrim(customer_id)::INTEGER,
    btrim(order_date)::TIMESTAMP WITHOUT TIME ZONE,
    btrim(online_order)::BOOLEAN,
    btrim(order_status)
FROM ranked_orders
WHERE duplicate_rank = 1;

-- Позиции заказов: преобразование типов и исключение повторов по order_item_id
WITH ranked_order_items AS (
    SELECT
        oi.*,
        ROW_NUMBER() OVER (
            PARTITION BY btrim(oi.order_item_id)::INTEGER
            ORDER BY oi.source_row_id
        ) AS duplicate_rank
    FROM raw.order_items AS oi
)
INSERT INTO core.order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    item_list_price_at_sale,
    item_standard_cost_at_sale
)
SELECT
    btrim(order_item_id)::INTEGER,
    btrim(order_id)::INTEGER,
    btrim(product_id)::INTEGER,
    btrim(quantity)::SMALLINT,
    btrim(item_list_price_at_sale)::NUMERIC(12, 2),
    btrim(item_standard_cost_at_sale)::NUMERIC(12, 2)
FROM ranked_order_items
WHERE duplicate_rank = 1;

COMMIT;

-- Контрольные величины после исполнения (преобразования):
-- locations   = 2899
-- customers   = 5000
-- products    = 300
-- orders      = 25000
-- order_items = 50000

--как они получены? Я проверил, что число строк итоговой таблицы против числа уникальных записей по бизнес-ключам искодных таблиц
--прогнал этот запрос на каждой из таблиц - customer_id менял на соответсвубщие свои в таблицах
--SELECT
--    COUNT(*) AS source_rows,
--    COUNT(DISTINCT btrim(customer_id)::INTEGER) AS unique_keys,
--    COUNT(*) - COUNT(DISTINCT btrim(customer_id)::INTEGER) AS duplicates
--FROM raw.customers;

--ВАЖНО!
--locations нет в исходном массиве, это составная запись из комбинации postcode + state + country
--эту сущность протестировал отдельно запросом
--SELECT COUNT(*)
--FROM (
--    SELECT DISTINCT
--        btrim(postcode),
--        btrim(state),
--        btrim(country)
--    FROM raw.customers
--) AS unique_locations;

-- ВАЖНО! 2887 уникальных индексов + 12 дополнительных сочетаний с другим регионом = 2899 locations
-- итого - уникальных 2899 записей


SELECT 'locations' AS table_name, COUNT(*) AS row_count
FROM core.locations
UNION ALL
SELECT 'customers', COUNT(*)
FROM core.customers
UNION ALL
SELECT 'products', COUNT(*)
FROM core.products
UNION ALL
SELECT 'orders', COUNT(*)
FROM core.orders
UNION ALL
SELECT 'order_items', COUNT(*)
FROM core.order_items
ORDER BY table_name;
