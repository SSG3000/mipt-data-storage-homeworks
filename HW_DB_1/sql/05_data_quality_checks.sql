-- HW_DB_1
-- Контрольный скрипт для оценки качества после загрузки core


-- 1. Итоговая таблица анализа ключей и дублей для отчета
WITH table_metrics AS (
    SELECT
        'customers'::TEXT AS table_name,
        'customer_id'::TEXT AS primary_key,
        'location_id -> core.locations(location_id)'::TEXT AS foreign_keys,
        (SELECT COUNT(*) FROM raw.customers) AS source_rows,
        (
            SELECT COUNT(DISTINCT btrim(customer_id)::INTEGER)
            FROM raw.customers
        ) AS unique_keys,
        (SELECT COUNT(*) FROM core.customers) AS final_rows

    UNION ALL

    SELECT
        'products',
        'product_id',
        'нет',
        (SELECT COUNT(*) FROM raw.products),
        (
            SELECT COUNT(DISTINCT btrim(product_id)::INTEGER)
            FROM raw.products
        ),
        (SELECT COUNT(*) FROM core.products)

    UNION ALL

    SELECT
        'orders',
        'order_id',
        'customer_id -> core.customers(customer_id)',
        (SELECT COUNT(*) FROM raw.orders),
        (
            SELECT COUNT(DISTINCT btrim(order_id)::INTEGER)
            FROM raw.orders
        ),
        (SELECT COUNT(*) FROM core.orders)

    UNION ALL

    SELECT
        'order_items',
        'order_item_id',
        'order_id -> core.orders(order_id); product_id -> core.products(product_id)',
        (SELECT COUNT(*) FROM raw.order_items),
        (
            SELECT COUNT(DISTINCT btrim(order_item_id)::INTEGER)
            FROM raw.order_items
        ),
        (SELECT COUNT(*) FROM core.order_items)
)
SELECT
    table_name,
    primary_key,
    foreign_keys,
    source_rows,
    unique_keys,
    source_rows - unique_keys AS duplicate_rows,
    'ROW_NUMBER(): сохранена первая строка по source_row_id' AS deduplication_method,
    final_rows,
    unique_keys = final_rows AS row_count_check_passed
FROM table_metrics
ORDER BY table_name;

-- 2. Проверка производной таблицы locations
SELECT
    'locations' AS table_name,
    COUNT(*) AS source_customer_rows,
    COUNT(DISTINCT (
        btrim(postcode),
        btrim(state),
        btrim(country)
    )) AS unique_location_combinations,
    (SELECT COUNT(*) FROM core.locations) AS final_rows,
    COUNT(DISTINCT (
        btrim(postcode),
        btrim(state),
        btrim(country)
    )) = (SELECT COUNT(*) FROM core.locations) AS row_count_check_passed
FROM raw.customers;

-- 3. Проверка ссылочной целостности - трассировка от order_items к products и orders (далее к customers, и далее к locations) 
-- Все значения orphan_rows ("потеряшки" / "сироты") должны быть равны нулю

WITH orphan_checks AS (
    SELECT
        'core.customers.location_id -> core.locations.location_id'::TEXT AS relationship,
        COUNT(*) AS orphan_rows
    FROM core.customers AS c
    LEFT JOIN core.locations AS l
        ON l.location_id = c.location_id
    WHERE l.location_id IS NULL

    UNION ALL

    SELECT
        'core.orders.customer_id -> core.customers.customer_id',
        COUNT(*)
    FROM core.orders AS o
    LEFT JOIN core.customers AS c
        ON c.customer_id = o.customer_id
    WHERE c.customer_id IS NULL

    UNION ALL

    SELECT
        'core.order_items.order_id -> core.orders.order_id',
        COUNT(*)
    FROM core.order_items AS oi
    LEFT JOIN core.orders AS o
        ON o.order_id = oi.order_id
    WHERE o.order_id IS NULL

    UNION ALL

    SELECT
        'core.order_items.product_id -> core.products.product_id',
        COUNT(*)
    FROM core.order_items AS oi
    LEFT JOIN core.products AS p
        ON p.product_id = oi.product_id
    WHERE p.product_id IS NULL
)
SELECT
    relationship,
    orphan_rows,
    orphan_rows = 0 AS relationship_check_passed
FROM orphan_checks
ORDER BY relationship;
