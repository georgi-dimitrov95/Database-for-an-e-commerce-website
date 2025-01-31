-- Represents users of the website
CREATE TABLE "user" (
    "id" INTEGER,
    "username" TEXT UNIQUE NOT NULL CHECK(LENGTH("username") > 6),
    "password" TEXT NOT NULL,
    "email" TEXT UNIQUE NOT NULL ,
    "phone_number" TEXT NOT NULL,
    PRIMARY KEY("id")
);

-- Represents delivery addresses
CREATE TABLE "address" (
    "id" INTEGER,
    "region" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "neighbourhood" TEXT,
    "street" TEXT,
    "number" INTEGER,
    "entrance" TEXT,
    "floor" INTEGER,
    "apartment" INTEGER,
    "postal_code" INTEGER,
    PRIMARY KEY("id")
);

-- Represents the many-to-many relationship between users and addresses
CREATE TABLE "user_address" (
    "user_id" INTEGER,
    "address_id" INTEGER,
    "is_default" INTEGER NOT NULL CHECK("is_default" = 0 OR "is_default" = 1),
    PRIMARY KEY("user_id", "address_id"),
    FOREIGN KEY("user_id") REFERENCES "user"("id") ON DELETE CASCADE,
    FOREIGN KEY("address_id") REFERENCES "address"("id") ON DELETE CASCADE
);

-- Represents the products sold in the website
CREATE TABLE "product" (
    "id" INTEGER,
    "product_number" TEXT UNIQUE NOT NULL,
    "category_id" INTEGER,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "quantity_in_stock" INTEGER NOT NULL CHECK("quantity_in_stock" >= 0),
    "price" REAL NOT NULL CHECK("price" >= 0),
    "archived" INTEGER NOT NULL CHECK("archived" = 0 OR "archived" = 1),
    PRIMARY KEY("id"),
    FOREIGN KEY("category_id") REFERENCES "category"("id") ON DELETE SET NULL
);

-- Represents the changes to product prices throughout time
CREATE TABLE "product_price_history" (
    "product_id" INTEGER NOT NULL,
    "changed_at" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "old_price" REAL NOT NULL CHECK("old_price" >= 0),
    "new_price" REAL NOT NULL CHECK("new_price" >= 0),
    FOREIGN KEY("product_id") REFERENCES "product"("id") ON DELETE NO ACTION
);

-- Represents the categories that a product might fall into
-- Self referencing table, used to represent the hierarchical structure of categories and subcategories
CREATE TABLE "category" (
    "id" INTEGER,
    "parent_category_id" INTEGER,
    "name" TEXT UNIQUE NOT NULL,
    PRIMARY KEY("id"),
    FOREIGN KEY("parent_category_id") REFERENCES "category"("id") ON DELETE NO ACTION
);

-- Represents images used in the visualization of products
CREATE TABLE "product_image" (
    "id" INTEGER,
    "product_id" INTEGER,
    "path" TEXT UNIQUE NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "type" TEXT,
    "size" INTEGER,
    PRIMARY KEY("id"),
    FOREIGN KEY("product_id") REFERENCES "product"("id") ON DELETE SET NULL
);

-- Represents the many-to-many relationship between users and products set as favorite
CREATE TABLE "user_favorite_product" (
    "user_id" INTEGER,
    "product_id" INTEGER,
    PRIMARY KEY("user_id", "product_id"),
    FOREIGN KEY("user_id") REFERENCES "user"("id") ON DELETE CASCADE,
    FOREIGN KEY("product_id") REFERENCES "product"("id") ON DELETE CASCADE
);

-- Represents each user's shopping cart product items
CREATE TABLE "shopping_cart" (
    "user_id" INTEGER,
    "product_id" INTEGER,
    "quantity" INTEGER NOT NULL CHECK("quantity" > 0),
    PRIMARY KEY("user_id", "product_id"),
    FOREIGN KEY("user_id") REFERENCES "user"("id") ON DELETE CASCADE,
    FOREIGN KEY("product_id") REFERENCES "product"("id") ON DELETE CASCADE
);

-- Represents the user's payment method (only card payment supported)
CREATE TABLE "user_payment_method" (
    "id" INTEGER,
    "user_id" INTEGER NOT NULL,
    "card_number" TEXT UNIQUE NOT NULL CHECK(LENGTH("card_number") = 16),
    "card_holder" TEXT NOT NULL,
    "expiry_date" NUMERIC NOT NULL,
    "cvv" TEXT NOT NULL CHECK(LENGTH("cvv") = 3),
    "is_default" INTEGER NOT NULL CHECK("is_default" = 0 OR "is_default" = 1),
    PRIMARY KEY("id"),
    FOREIGN KEY("user_id") REFERENCES "user"("id") ON DELETE CASCADE
);

-- Represents the orders made by users
CREATE TABLE "shop_order" (
    "id" INTEGER,
    "user_id" INTEGER NOT NULL,
    "order_date_time" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "shipping_address_id" INTEGER NOT NULL,
    "shipping_method_id" INTEGER NOT NULL,
    "payment_method_id" INTEGER NOT NULL,
    "order_total" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id"),
    FOREIGN KEY("user_id") REFERENCES "user"("id") ON DELETE NO ACTION,
    FOREIGN KEY("shipping_address_id") REFERENCES "address"("id") ON DELETE NO ACTION,
    FOREIGN KEY("shipping_method_id") REFERENCES "shipping_method"("id") ON DELETE NO ACTION,
    FOREIGN KEY("payment_method_id") REFERENCES "user_payment_method"("id") ON DELETE NO ACTION
);

-- Represents the product items in each order
CREATE TABLE "order_product" (
    "order_id" INTEGER,
    "product_id" INTEGER,
    "quantity" INTEGER NOT NULL CHECK("quantity" > 0),
    "total_price" REAL NOT NULL CHECK("total_price" > 0),
    PRIMARY KEY("order_id", "product_id"),
    FOREIGN KEY("order_id") REFERENCES "shop_order"("id") ON DELETE CASCADE,
    FOREIGN KEY("product_id") REFERENCES "product"("id") ON DELETE NO ACTION
);

-- Represents the statuses of orders (one order can have many statuses throughout its fulfillment)
CREATE TABLE "order_status" (
    "id" INTEGER,
    "order_id" INTEGER,
    "status" TEXT NOT NULL,
    "timestamp" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id"),
    FOREIGN KEY("order_id") REFERENCES "shop_order"("id") ON DELETE NO ACTION
);

-- Represents the type of shipping method used in an order
CREATE TABLE "shipping_method" (
    "id" INTEGER,
    "company" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "price" REAL NOT NULL CHECK("price" >= 0),
    PRIMARY KEY("id")
);

-- Create indexes to speed common searches
CREATE INDEX "user_address_user_id_index" ON "user_address"("user_id");
CREATE INDEX "product_name_index" ON "product"("name");
CREATE INDEX "product_description_index" ON "product"("description");
CREATE INDEX "product_image_product_id_index" ON "product_image"("product_id");
CREATE INDEX "user_payment_user_id_index" ON "user_payment_method"("user_id");
CREATE INDEX "order_user_id_index" ON "shop_order"("user_id");
CREATE INDEX "order_status_order_id_index" ON "order_status"("order_id");

-- Create views to simplify queries
CREATE VIEW "products_in_stock" AS
SELECT *
FROM "product"
WHERE "quantity_in_stock" > 0;

CREATE VIEW "products_offered" AS
SELECT *
FROM "product"
WHERE "archived" = 0;

CREATE VIEW "delivered_orders" AS
SELECT *
FROM "shop_order"
WHERE "id" IN (
    SELECT "order_id"
    FROM "order_status"
    WHERE "status" = 'Successfully delivered'
);

-- Create triggers to automate some processes
CREATE TRIGGER "add_to_price_history"
AFTER UPDATE OF "price" ON "product"
FOR EACH ROW
BEGIN
    INSERT INTO "product_price_history"("product_id", "changed_at", "old_price", "new_price")
    VALUES (OLD."id", CURRENT_TIMESTAMP, OLD."price", NEW."price");
END;

CREATE TRIGGER "update_product_quantities_after_orders"
AFTER INSERT ON "order_product"
FOR EACH ROW
BEGIN
    UPDATE "product"
    SET "quantity_in_stock" = "quantity_in_stock" - NEW."quantity"
    WHERE "id" = NEW."product_id";
END;
