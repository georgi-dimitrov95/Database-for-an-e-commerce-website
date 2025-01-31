-- A few examples of some common (and others not so common) queries that might be used to read data from the tables. Some of the queries will be a result of users interacting with the website, while others might be used by the website administrators to gather data about user behavior.

-- Find user info by id
SELECT *
FROM "user"
WHERE "id" = 3;

-- Find address(es) info of user by user_id
SELECT *
FROM address
WHERE "id" IN (
    SELECT "address_id"
    FROM "user_address"
    WHERE "user_id" = 7
);

-- Find full product info by name/description from actively offered products
SELECT *
FROM "products_offered"
WHERE name LIKE '%Mouse%' OR description LIKE '%Mouse%';

-- Update the prices of each product from a given category (by id). Such updates are recorded in the "product_price_history" table.
UPDATE "product"
SET "price" = "price" + 10.00
WHERE "category_id" = 1;

-- Find all products (in stock) for a given (sub)category ordered by price from highest to lowest.
SELECT *
FROM "products_in_stock"
WHERE "category_id" = (
    SELECT "id"
    FROM "category"
    WHERE "name" = 'Computer Accessories'
)
ORDER BY "price" DESC;

-- Find the top 5 (sub)categories with the highest number of products, the count of those products and the sum of their quantities in stock.
SELECT category.name, COUNT(*) AS "unique_products", SUM(product.quantity_in_stock) AS "total_items"
FROM "category"
RIGHT JOIN "product" ON category.id = product.category_id
GROUP BY category.id
ORDER BY "unique_products" DESC, "total_items" DESC
LIMIT 5;

-- Find favorite products by user_id
SELECT *
FROM "user_favorite_product"
JOIN "product" ON user_favorite_product.product_id = product.id
WHERE "user_id" = 50;

-- Find all products in the shopping cart of a user (search by user id)
SELECT product.*, shopping_cart.quantity
FROM "product"
JOIN "shopping_cart" ON product.id = shopping_cart.product_id
JOIN "user" ON shopping_cart.user_id = user.id
WHERE user.id = 10;

-- Calculate the total value of a user's shopping cart
SELECT SUM("quantity" * "price") AS "total"
FROM "shopping_cart"
JOIN "product" ON shopping_cart.product_id = product.id
WHERE "user_id" = 50;

-- In descending order find every "Thermostat" product above 50$ that has been saved as "favorite" at least 3 times among all users
SELECT "name", COUNT(*) AS "favorite_count"
FROM "user_favorite_product"
JOIN "product" ON user_favorite_product.product_id = product.id
WHERE "name" LIKE '%Thermostat%' AND "price" >= 50
GROUP BY product.id
HAVING "favorite_count" >= 3
ORDER BY "favorite_count" DESC;

-- Find the single most expensive order from Sofia in the last 30 days
SELECT date("order_date_time") AS "date", MAX("order_total") AS "max_order_sofia"
FROM "shop_order"
JOIN "address" ON shop_order.shipping_address_id = address.id
WHERE "city" = 'Sofia' AND "date" >= date('now', '-30 days')
GROUP BY "date"
ORDER BY "date" DESC;

-- Find the products among the top 10 most favorite products and the 10 least
-- ordered ones (excluding quantities). Order them by the % ratio of ordered/favorite in ascending order
WITH "most_favorite" AS (
    SELECT product.id, product.name, product.product_number, COUNT(*) AS "favorite"
    FROM "product"
    JOIN "user_favorite_product" ON product.id = user_favorite_product.product_id
    GROUP BY product.id
    ORDER BY "favorite" DESC
    LIMIT 10
),
"least_ordered" AS (
    SELECT product.id, COUNT(*) AS "ordered"
    FROM "product"
    JOIN "order_product" ON product.id = order_product.product_id
    GROUP BY product.id
    ORDER BY "ordered"
    LIMIT 10
)
SELECT "name", "product_number", "favorite", "ordered", ROUND(("ordered" / ("favorite" * 1.0)), 2) AS "ratio"
FROM "most_favorite"
JOIN "least_ordered" ON most_favorite.id = least_ordered.id
ORDER BY "ratio", "name", "product_number"
;
