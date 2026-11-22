-- HW_DB_1
-- Выполнение Шага 3 ДЗ - 11 запросов для формирования выходных таблиц

--Запрос1: Выведите id продукта и среднюю цену продажи (item_list_price_at_sale) для 5 продуктов с самой высокой средней ценой продажи.
--Запрос2: Рассчитайте общую стоимость заказа (item_list_price_at_sale * quantity) для каждого бренда продукта.
--Запрос3: Подсчитайте количество заказов за каждый месяц для каждого года. То есть необходимо вывести год, месяц и количество заказов.
--Запрос4: Для каждой продуктовой линейки (product_line) найдите продукт с самой высокой стандартной стоимостью (standard_cost). Выведите id продукта, линейку продукта и стандартную стоимость.
--Запрос5: Подсчитайте количество заказов и общую стоимость заказов для каждого статуса заказа (order_status). Общую стоимость заказа необходимо рассчитать как цену продукта на момент продажи, умноженную на количество единиц продукта в заказе.
--Запрос6: Найдите клиентов, у которых нет ни одного заказа. Выведите id клиента, фамилию и имя.
--Запрос7: Для каждого штата найдите клиента с самой высокой и самой низкой оценкой стоимости имущества (property_valuation). Выведите штат, оценку стоимости имущества, фамилию и имя клиента.
--Запрос8: Найдите клиентов, которые покупали продукты только из одной продуктовой линейки (product_line). Выведите id клиента, линейку продукта и количество заказов.
--Запрос9: Для каждой категории продуктов рассчитайте процент отмененных заказов (order_status = 'Cancelled').
--Запрос10: Разделите клиентов на сегменты на основе количества заказов и подсчитайте количество клиентов в каждом сегменте:
-- * сегмент High, если количество заказов больше 10;
-- * сегмент Medium, если количество заказов от 5 до 10;
-- * иначе сегмент Low.
--Запрос11: Для всех клиентов выведите имена, фамилии, профессии, а также длительность максимального интервала (в днях) между двумя последовательными заказами. Необходимо исключить клиентов, у которых только один заказ или меньше.


-- Запрос 1.
-- Пять продуктов с самой высокой средней ценой продажи
SELECT
    oi.product_id,
    ROUND(AVG(oi.item_list_price_at_sale), 2) AS average_sale_price
FROM core.order_items AS oi
GROUP BY oi.product_id
ORDER BY
    average_sale_price DESC,
    oi.product_id
LIMIT 5;

-- Запрос 2.
-- Общая стоимость проданных товаров для каждого бренда
SELECT
    p.brand,
    ROUND(SUM(oi.item_list_price_at_sale * oi.quantity), 2) AS total_order_value
FROM core.order_items AS oi
JOIN core.products AS p
    ON p.product_id = oi.product_id
GROUP BY p.brand
ORDER BY
    total_order_value DESC,
    p.brand;

-- Запрос 3.
-- Количество заказов за каждый месяц каждого года
-- изначально был числовой формат в order_year - это выводило год как 2,017 - пришлось переписать 
-- под формат текста, месяц заодно тоже
SELECT
    TO_CHAR(o.order_date, 'YYYY') AS order_year,
    TO_CHAR(o.order_date, 'MM') AS order_month,
    COUNT(*) AS order_count
FROM core.orders AS o
GROUP BY
    TO_CHAR(o.order_date, 'YYYY'),
    TO_CHAR(o.order_date, 'MM')
ORDER BY
    order_year,
    order_month;

-- Запрос 4.
-- Продукт с максимальной стандартной стоимостью в каждой продуктовой линейке
-- Вложенный запрос находит максимальную стоимость каждой линейки,
-- после чего результат соединяется с таблицей продуктов
SELECT
    p.product_id,
    p.product_line,
    p.standard_cost
FROM core.products AS p
JOIN (
    SELECT
        product_line,
        MAX(standard_cost) AS maximum_standard_cost
    FROM core.products
    GROUP BY product_line
) AS maximum_costs
    ON maximum_costs.product_line = p.product_line
   AND maximum_costs.maximum_standard_cost = p.standard_cost
ORDER BY
    p.product_line,
    p.product_id;

-- Запрос 5.
-- Количество заказов и общая стоимость заказов для каждого статуса
-- DISTINCT не дает учитывать один заказ несколько раз из-за нескольких позиций (отбирает уникальный)
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(
        SUM(oi.item_list_price_at_sale * oi.quantity),
        2
    ) AS total_order_value
FROM core.orders AS o
LEFT JOIN core.order_items AS oi
    ON oi.order_id = o.order_id
GROUP BY o.order_status
ORDER BY o.order_status;

-- Запрос 6.
-- Клиенты, у которых нет ни одного заказа
SELECT
    c.customer_id,
    c.last_name,
    c.first_name
FROM core.customers AS c
LEFT JOIN core.orders AS o
    ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- Запрос 7.
-- Клиенты с максимальной и минимальной оценкой стоимости имущества
-- в каждом штате. При равной оценке выбирается клиент с меньшим ID
-- DISTINCT ON после сортировки оставляет первую запись каждого штата,
-- а UNION ALL объединяет результаты для максимальных и минимальных оценок
SELECT
    state,
    property_valuation,
    last_name,
    first_name
FROM (
    (
        SELECT DISTINCT ON (l.state)
            l.state,
            1 AS level_order,
            c.property_valuation,
            c.last_name,
            c.first_name
        FROM core.customers AS c
        JOIN core.locations AS l
            ON l.location_id = c.location_id
        ORDER BY
            l.state,
            c.property_valuation DESC NULLS LAST,
            c.customer_id
    )

    UNION ALL

    (
        SELECT DISTINCT ON (l.state)
            l.state,
            2 AS level_order,
            c.property_valuation,
            c.last_name,
            c.first_name
        FROM core.customers AS c
        JOIN core.locations AS l
            ON l.location_id = c.location_id
        ORDER BY
            l.state,
            c.property_valuation ASC NULLS LAST,
            c.customer_id
    )
) AS selected_customers
ORDER BY
    state,
    level_order;

-- Запрос 8.
-- Клиенты, покупавшие продукты только из одной продуктовой линейки
SELECT
    c.customer_id,
    MIN(p.product_line) AS product_line,
    COUNT(DISTINCT o.order_id) AS order_count
FROM core.customers AS c
JOIN core.orders AS o
    ON o.customer_id = c.customer_id
JOIN core.order_items AS oi
    ON oi.order_id = o.order_id
JOIN core.products AS p
    ON p.product_id = oi.product_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT p.product_line) = 1
ORDER BY c.customer_id;

-- Запрос 9.
-- Процент отмененных заказов для каждой категории продуктов
-- Один заказ учитывается в категории один раз независимо от числа позиций
-- Второе соединение с orders оставляет id только у отмененных заказов
SELECT
    p.product_class,
    ROUND(
        100.0
        * COUNT(DISTINCT cancelled_orders.order_id)
        / COUNT(DISTINCT all_orders.order_id),
        2
    ) AS cancelled_order_percentage
FROM core.products AS p
JOIN core.order_items AS oi
    ON oi.product_id = p.product_id
JOIN core.orders AS all_orders
    ON all_orders.order_id = oi.order_id
LEFT JOIN core.orders AS cancelled_orders
    ON cancelled_orders.order_id = all_orders.order_id
   AND cancelled_orders.order_status = 'Cancelled'
GROUP BY p.product_class
ORDER BY p.product_class;

-- Запрос 10.
-- Количество клиентов в сегментах по числу заказов
-- Каждый вложенный запрос считает заказы клиентов,
-- а UNION ALL объединяет три непересекающихся сегмента
SELECT
    customer_segment,
    customer_count
FROM (
    SELECT
        1 AS segment_order,
        'High' AS customer_segment,
        COUNT(*) AS customer_count
    FROM (
        SELECT
            c.customer_id,
            COUNT(o.order_id) AS order_count
        FROM core.customers AS c
        LEFT JOIN core.orders AS o
            ON o.customer_id = c.customer_id
        GROUP BY c.customer_id
    ) AS customer_order_counts
    WHERE order_count > 10

    UNION ALL

    SELECT
        2 AS segment_order,
        'Medium' AS customer_segment,
        COUNT(*) AS customer_count
    FROM (
        SELECT
            c.customer_id,
            COUNT(o.order_id) AS order_count
        FROM core.customers AS c
        LEFT JOIN core.orders AS o
            ON o.customer_id = c.customer_id
        GROUP BY c.customer_id
    ) AS customer_order_counts
    WHERE order_count BETWEEN 5 AND 10

    UNION ALL

    SELECT
        3 AS segment_order,
        'Low' AS customer_segment,
        COUNT(*) AS customer_count
    FROM (
        SELECT
            c.customer_id,
            COUNT(o.order_id) AS order_count
        FROM core.customers AS c
        LEFT JOIN core.orders AS o
            ON o.customer_id = c.customer_id
        GROUP BY c.customer_id
    ) AS customer_order_counts
    WHERE order_count < 5
) AS customer_segments
ORDER BY segment_order;

-- Запрос 11.
-- Максимальный интервал в днях между последовательными заказами клиента
-- Клиенты с одним заказом или без заказов автоматически исключаются
-- LAG находит предыдущий заказ клиента во вложенном 
-- запросе (перевод дней идет из расчета количества секунд в сутках 86400.0),
-- после чего MAX выбирает самый большой интервал
SELECT
    c.first_name,
    c.last_name,
    c.job_title,
    ROUND(
        MAX(
            EXTRACT(
                EPOCH FROM (
                    sequenced_orders.order_date
                    - sequenced_orders.previous_order_date
                )
            )
            / 86400.0
        ),
        2
    ) AS maximum_interval_days
FROM (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        LAG(o.order_date) OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS previous_order_date
    FROM core.orders AS o
) AS sequenced_orders
JOIN core.customers AS c
    ON c.customer_id = sequenced_orders.customer_id
WHERE sequenced_orders.previous_order_date IS NOT NULL
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_title
ORDER BY
    maximum_interval_days DESC,
    c.customer_id;

-- Запрос 11.1.
-- Компактный результат запроса 11 для одного скриншота:
-- первые 10 и последние 10 строк из полной выборки
WITH sequenced_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        LAG(o.order_date) OVER (
            PARTITION BY o.customer_id
            ORDER BY o.order_date, o.order_id
        ) AS previous_order_date
    FROM core.orders AS o
), customer_intervals AS (
    SELECT
        customer_id,
        MAX(
            EXTRACT(EPOCH FROM (order_date - previous_order_date))
            / 86400.0
        ) AS maximum_interval_days
    FROM sequenced_orders
    WHERE previous_order_date IS NOT NULL
    GROUP BY customer_id
), complete_result AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.job_title,
        ROUND(ci.maximum_interval_days, 2) AS maximum_interval_days
    FROM customer_intervals AS ci
    JOIN core.customers AS c
        ON c.customer_id = ci.customer_id
), numbered_result AS (
    SELECT
        complete_result.*,
        ROW_NUMBER() OVER (
            ORDER BY maximum_interval_days DESC, customer_id
        ) AS result_row,
        COUNT(*) OVER () AS total_rows
    FROM complete_result
)
SELECT
    result_row,
    first_name,
    last_name,
    job_title,
    maximum_interval_days,
    total_rows
FROM numbered_result
WHERE result_row <= 10
   OR result_row > total_rows - 10
ORDER BY result_row;
