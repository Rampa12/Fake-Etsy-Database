CREATE TABLE sellers (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(250) NOT NULL,
    seller_country varchar(250) NOT NULL
);

DROP TABLE IF EXISTS buyers;
CREATE TABLE buyers(
    buyer_id INT PRIMARY KEY,
    first_name VARCHAR(250)NOT NULL,
    last_name VARCHAR(250)NOT NULL,
    email VARCHAR(250)NOT NULL,
    city VARCHAR(250)NOT NULL,
    country VARCHAR(250)NOT NULL
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_price DECIMAL(10,2) NOT NULL,
    product_name VARCHAR (250) NOT NULL,
    seller_id INT NOT NULL,
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);


CREATE TABLE buyers_address(
    address_id INT PRIMARY KEY,
    buyer_id INT NOT NULL,
    address VARCHAR(250) NOT NULL,
    city VARCHAR(250) NOT NULL,
    country VARCHAR(250 ) NOT NULL,
    FOREIGN KEY (buyer_id) REFERENCES buyers(buyer_id) 
);



CREATE TABLE credit_cards(
    cc_number VARCHAR (250 ) PRIMARY KEY,
    cc_exp VARCHAR (250 ) NOT NULL,
    buyer_id INT NOT NULL,
    FOREIGN KEY (buyer_id) REFERENCES buyers(buyer_id)
);


CREATE TABLE orders(
    order_id INT PRIMARY KEY,
    order_quantity INT NOT NULL,
    order_date DATE NOT NULL,
    buyer_id INT NOT NULL, 
    seller_id INT NOT NULL,
    product_id INT NOT NULL,
    FOREIGN KEY (buyer_id) REFERENCES buyers(buyer_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE reviews(
     review_id INT PRIMARY KEY,
     review VARCHAR(250) NOT NULL,
     rating DECIMAL(5,1) NOT NULL,
     order_id INT NOT NULL,
     FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- Insert data into sellers
INSERT INTO sellers (seller_id, seller_name, seller_country)
SELECT DISTINCT seller_id, seller_name, seller_country
FROM denormalized;

-- Insert data into buyers
INSERT INTO buyers (buyer_id, first_name, last_name, email, city, country)
SELECT DISTINCT buyer_id, first_name, last_name, email, city, country
FROM denormalized;

-- Insert data into products
INSERT INTO products (product_id, product_price, product_name, seller_id)
SELECT DISTINCT product_id, product_price, product_name, seller_id
FROM denormalized;

-- Insert data into buyers_address
INSERT INTO buyers_address (buyer_id, address, city, country)
SELECT DISTINCT buyer_id, address, city, country
FROM denormalized;


-- Insert data into credit_cardsINSERT INTO credit_cards (cc_number, cc_exp, buyer_id)
INSERT INTO credit_cards (buyer_id)
SELECT DISTINCT buyer_id
FROM denormalized;

-- Insert data into orders
INSERT INTO orders (order_id, order_quantity, order_date, buyer_id, seller_id, product_id)
SELECT DISTINCT order_id, order_quantity, order_date, buyer_id, seller_id, product_id
FROM denormalized;

-- Insert data into reviews
INSERT INTO reviews (review, rating, order_id)
SELECT DISTINCT review, rating, order_id
FROM denormalized;

CREATE INDEX idx_country ON buyers (country);

-- Add index to optimize joins on buyer_id
CREATE INDEX idx_buyer_id_orders ON orders (buyer_id);
CREATE INDEX idx_buyer_id_address ON buyers_address (buyer_id);
CREATE INDEX idx_buyer_id_cc ON credit_cards (buyer_id);

-- Add index to optimize joins on seller_id
CREATE INDEX idx_seller_id_orders ON orders (seller_id);
CREATE INDEX idx_seller_id_product ON products (seller_id);

-- Add index to optimize joins on product_id
CREATE INDEX idx_product_id_orders ON orders (product_id);
CREATE INDEX idx_product_id ON products (product_id); 

-- Add index to optimize joins on order_id
CREATE INDEX idx_order_id_reviews ON reviews (order_id);


DELIMITER $$
CREATE PROCEDURE top_ten_for_country(IN country_name VARCHAR(100))
BEGIN
    SELECT 
        b.buyer_id,
        b.first_name,
        b.last_name,
        CONCAT('$', FORMAT(SUM(p.product_price * o.order_quantity), 2)) AS total_amount_spent
    FROM 
        buyers b
    JOIN 
        orders o ON b.buyer_id = o.buyer_id
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        b.country = country_name
    GROUP BY 
        b.buyer_id, b.first_name, b.last_name
    ORDER BY 
        total_amount_spent DESC
    LIMIT 10;
END$$

DELIMITER ;




DROP PROCEDURE IF EXISTS top_ten_for_country;

CREATE VIEW top_rated_products AS
SELECT 
    p.product_id,
    p.product_name,
    CONCAT('$', FORMAT(p.product_price, 2)) AS product_price,
    AVG(r.rating) AS avg_rating,
    COUNT(r.rating) AS rating_count
FROM 
    products p
JOIN 
    orders o ON p.product_id = o.product_id
JOIN 
    reviews r ON o.order_id = r.order_id
GROUP BY 
    p.product_id, p.product_name, p.product_price
HAVING 
    COUNT(r.rating) >= 20 -- Minimum of 20 ratings
ORDER BY 
    avg_rating DESC -- Order by highest average rating
LIMIT 10;



DELIMITER $$

CREATE PROCEDURE buyer_for_date(
    IN buyer_first_name VARCHAR(250),
    IN buyer_last_name VARCHAR(250),
    IN given_order_date DATE
)
BEGIN
    SELECT 
        o.order_id,
        o.order_quantity,
        p.product_name,
        o.order_date
    FROM 
        buyers b
    JOIN 
        orders o ON b.buyer_id = o.buyer_id
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        b.first_name = buyer_first_name
        AND b.last_name = buyer_last_name
        AND o.order_date = given_order_date;
END$$

DELIMITER ;

CALL buyer_for_date('John', 'Doe', '2024-12-01');


CREATE VIEW top_five_buyer_cities AS
SELECT 
    b.city,
    CONCAT('$', FORMAT(SUM(p.product_price * o.order_quantity), 2)) AS total_amount_spent
FROM 
    buyers b
JOIN 
    orders o ON b.buyer_id = o.buyer_id
JOIN 
    products p ON o.product_id = p.product_id
GROUP BY 
    b.city
ORDER BY 
    SUM(p.product_price * o.order_quantity) DESC
LIMIT 5;

SELECT * FROM top_five_buyer_cities;




DELIMITER $$
CREATE PROCEDURE sales_for_month(
    IN target_month_year VARCHAR(7) -- Input format: YYYY-MM
)
BEGIN
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m') AS month_and_year,
        SUM(p.product_price * o.order_quantity) AS total_sales
    FROM 
        orders o
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        DATE_FORMAT(o.order_date, '%Y-%m') = target_month_year
    GROUP BY 
        month_and_year;
END$$

DELIMITER ; 
CALL sales_for_month('2024-12');





CREATE VIEW seller_sales_tiers AS
SELECT 
    s.seller_id,
    s.seller_name,
    CONCAT('$', FORMAT(SUM(p.product_price * o.order_quantity), 2)) AS total_sales,
    CASE
        WHEN SUM(p.product_price * o.order_quantity) >= 100000 THEN 'High'
        WHEN SUM(p.product_price * o.order_quantity) >= 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_tier
FROM 
    sellers s
JOIN 
    products p ON s.seller_id = p.seller_id
JOIN 
    orders o ON p.product_id = o.product_id
GROUP BY 
    s.seller_id, s.seller_name;SELECT * FROM seller_sales_tiers;




DELIMITER $$
CREATE PROCEDURE top_products_for_seller(
    IN seller_name_input VARCHAR(250)
)
BEGIN
    SELECT 
        s.seller_id,
        p.product_id,
        p.product_name,
        CONCAT('$', FORMAT(SUM(p.product_price * o.order_quantity), 2)) AS total_sales
    FROM 
        sellers s
    JOIN 
        products p ON s.seller_id = p.seller_id
    JOIN 
        orders o ON p.product_id = o.product_id
    WHERE 
        s.seller_name = seller_name_input
    GROUP BY 
        s.seller_id, p.product_id, p.product_name
    ORDER BY 
        SUM(p.product_price * o.order_quantity) DESC;
END$$

DELIMITER ;

SELECT * FROM seller_sales_tiers;


DELIMITER $$

CREATE PROCEDURE seller_running_totals(
    IN seller_name_input VARCHAR(250)
)
BEGIN
    SELECT 
        s.seller_id,
        o.order_id,
        o.order_date,
        CONCAT('$', FORMAT(SUM(p.product_price * o.order_quantity), 2)) AS order_total,
        CONCAT('$', FORMAT(SUM(SUM(p.product_price * o.order_quantity)) 
                           OVER (PARTITION BY s.seller_id ORDER BY o.order_date), 2)) AS running_total
    FROM 
        sellers s
    JOIN 
        orders o ON s.seller_id = o.seller_id
    JOIN 
        products p ON o.product_id = p.product_id
    WHERE 
        s.seller_name = seller_name_input
    GROUP BY 
        s.seller_id, o.order_id, o.order_date
    ORDER BY 
        o.order_date;
END$$

DELIMITER ;


CALL seller_running_totals('John Doe');
