-- HW_DB_1
-- Обновляем схему и делайем ее обновляемой/"переустанавливаемой" 
-- (в рабочих базах я так не делаю, но для учебы можно слой с кор схемой сносить и пересоздавать
-- - при первом выполнении ее еще нет)


BEGIN;

DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA core;

-- География вынесена отдельно, чтобы исключить повторение связки
-- почтовый индекс + регион + страна у каждого клиента
CREATE TABLE core.locations (
    location_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    postcode VARCHAR(10) NOT NULL,
    state VARCHAR(10) NOT NULL,
    country VARCHAR(100) NOT NULL,
    CONSTRAINT uq_locations_postcode_state_country
        UNIQUE (postcode, state, country)
);

CREATE TABLE core.customers (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    dob DATE NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    job_industry_category VARCHAR(100) NOT NULL,
    wealth_segment VARCHAR(50) NOT NULL,
    deceased_indicator BOOLEAN NOT NULL,
    owns_car BOOLEAN NOT NULL,
    address VARCHAR(200) NOT NULL,
    location_id BIGINT NOT NULL,
    property_valuation NUMERIC(5, 2) NOT NULL,
    CONSTRAINT fk_customers_location
        FOREIGN KEY (location_id)
        REFERENCES core.locations (location_id),
    CONSTRAINT chk_customers_id_positive
        CHECK (customer_id > 0),
    CONSTRAINT chk_customers_gender
        CHECK (gender IN ('Female', 'Male', 'Non-binary', 'Prefer not to say')),
    CONSTRAINT chk_customers_property_valuation
        CHECK (property_valuation >= 0)
);

CREATE TABLE core.products (
    product_id INTEGER PRIMARY KEY,
    brand VARCHAR(100) NOT NULL,
    product_line VARCHAR(50) NOT NULL,
    product_class VARCHAR(50) NOT NULL,
    product_size VARCHAR(50) NOT NULL,
    list_price NUMERIC(12, 2) NOT NULL,
    standard_cost NUMERIC(12, 2) NOT NULL,
    CONSTRAINT chk_products_id_positive
        CHECK (product_id > 0),
    CONSTRAINT chk_products_list_price
        CHECK (list_price >= 0),
    CONSTRAINT chk_products_standard_cost
        CHECK (standard_cost >= 0)
);

CREATE TABLE core.orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    online_order BOOLEAN NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES core.customers (customer_id),
    CONSTRAINT chk_orders_id_positive
        CHECK (order_id > 0),
    CONSTRAINT chk_orders_status
        CHECK (order_status IN (
            'Approved',
            'Cancelled',
            'Delivered',
            'Processing',
            'Refunded',
            'Shipped'
        ))
);

CREATE TABLE core.order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity SMALLINT NOT NULL,
    item_list_price_at_sale NUMERIC(12, 2) NOT NULL,
    item_standard_cost_at_sale NUMERIC(12, 2) NOT NULL,
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES core.orders (order_id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES core.products (product_id),
    CONSTRAINT chk_order_items_id_positive
        CHECK (order_item_id > 0),
    CONSTRAINT chk_order_items_quantity_positive
        CHECK (quantity > 0),
    CONSTRAINT chk_order_items_list_price
        CHECK (item_list_price_at_sale >= 0),
    CONSTRAINT chk_order_items_standard_cost
        CHECK (item_standard_cost_at_sale >= 0)
);

-- Индексы для внешних ключей и основных соединений
CREATE INDEX idx_customers_location_id
    ON core.customers (location_id);

CREATE INDEX idx_orders_customer_id
    ON core.orders (customer_id);

CREATE INDEX idx_orders_order_date
    ON core.orders (order_date);

CREATE INDEX idx_order_items_order_id
    ON core.order_items (order_id);

CREATE INDEX idx_order_items_product_id
    ON core.order_items (product_id);

COMMIT;
