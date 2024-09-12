


CREATE TABLE orders (
    order_id INT NOT NULL PRIMARY KEY,
    order_quantity TINYINT NOT NULL,
    buyer_id INT NOT NULL,
    seller_id INT NOT NULL,
    product_id INT NOT NULL,
    order_date DATE NOT NULL,
    cc_num BIGINT NOT NULL,
    cc_exp VARCHAR(7) NOT NULL,
    review VARCHAR(255) NOT NULL,
    rating TINYINT NOT NULL,
    FOREIGN KEY (seller_id)
        REFERENCES sellers (id),
    FOREIGN KEY (product_id)
        REFERENCES product (id),
	FOREIGN KEY (buyer_id)
		REFERENCES buyer(id)
);

CREATE TABLE sellers (
    id INT NOT NULL PRIMARY KEY,
    seller_name VARCHAR(50) NOT NULL,
    seller_country VARCHAR(100) NOT NULL
);

CREATE TABLE buyer (
    id INT PRIMARY KEY NOT NULL ,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    email VARCHAR(255) NOT NULL,
    buyer_country VARCHAR(50) NOT NULL,
    buyer_city VARCHAR(50) NOT NULL,
    address VARCHAR(100) NOT NULL
);

CREATE TABLE product (
    id INT NOT NULL PRIMARY KEY,
    price INT NOT NULL,
    product_name VARCHAR(255) NOT NULL
);



INSERT INTO product(id, price, product_name)
SELECT DISTINCT product_id, product_price, product_name FROM denormalized;


INSERT INTO sellers(id, seller_name, seller_country)
SELECT DISTINCT seller_id, seller_name, seller_country FROM denormalized;

INSERT INTO buyer(id, first_name, last_name, email, buyer_country, buyer_city, address)
SELECT DISTINCT buyer_id, first_name, last_name, email, country, city, address FROM denormalized;




INSERT INTO orders (order_date, order_id, order_quantity, buyer_id, seller_id, product_id, cc_num, cc_exp, review, rating)
SELECT DISTINCT STR_TO_DATE(order_date, '%m-%d-%Y'), orderid, order_quantity, buyer_id, seller_id, product_id, cc_number, cc_exp, review, rating
FROM denormalized;



 
SELECT country, COUNT(*) AS CNT
FROM denormalized
GROUP BY country
HAVING COUNT(*) > 1;





DELIMITER //
CREATE PROCEDURE top_ten_for_country(IN country_name VARCHAR(50))
BEGIN
	SELECT b.id AS buyer_id, b.first_name, b.last_name,
         CONCAT('$', FORMAT(SUM(o.order_quantity * (p.price*0.01)), 2)) AS  total_amount_spent 
    FROM buyer b
    INNER JOIN orders o ON b.id = o.buyer_id
    INNER JOIN product p ON p.id = o.product_id
    WHERE b.buyer_country = country_name
    GROUP BY b.id, b.first_name, b.last_name
    ORDER BY SUM(o.order_quantity * p.price) DESC
    LIMIT 10;
END //
DELIMITER ;

CALL top_ten_for_country('Hong Kong');



CREATE VIEW top_rated_products 
AS
SELECT p.id, product_name, CONCAT('$', FORMAT((p.price/100), 2)) AS price, AVG(o.rating) AS avg_rating, count(o.rating) AS rating_cnt
FROM product p 
JOIN orders o ON p.id = o.product_id
GROUP BY p.id, product_name
HAVING rating_cnt > 19
ORDER BY avg_rating DESC
LIMIT 10;

SELECT * 
FROM top_rated_products;


DELIMITER //
CREATE PROCEDURE buyer_for_date(IN first_name VARCHAR(25), last_name VARCHAR(25), order_date DATE)
BEGIN
    SELECT o.order_id, o.order_quantity, p.product_name, o.order_date
    FROM orders o
    JOIN buyer b ON b.first_name = first_name AND b.last_name = last_name
    JOIN  product p ON o.product_id = p.id
    WHERE o.order_date = order_date AND o.buyer_id = b.id
    GROUP BY o.order_id, b.first_name, b.last_name;
END //
DELIMITER ;

CALL buyer_for_date('Olaide','Nwuzor','2023-12-03');



CREATE VIEW top_five_buyer_cities
AS
SELECT b.buyer_city, (CONCAT('$', FORMAT(SUM(o.order_quantity * (p.price*0.01)), 2))) AS  total_amount_spent 
FROM buyer b
JOIN orders o ON b.id = o.buyer_id
JOIN product p ON o.product_id = p.id    
GROUP BY b.buyer_city
ORDER BY SUM(o.order_quantity * p.price) DESC
LIMIT 5; 

SELECT * FROM top_five_buyer_cities;


DELIMITER //
CREATE PROCEDURE sales_for_month (IN time_frame DATE)
BEGIN 
	SELECT CONCAT(YEAR(time_frame), '-', MONTH(time_frame)) AS month_and_year, 
    CONCAT('$', FORMAT(SUM(o.order_quantity * (p.price/100)), 2)) AS total_sales
    FROM orders o
    JOIN product p ON o.product_id = p.id
    WHERE o.order_date = time_frame
    GROUP BY month_and_year;
    
    
END //    
DELIMITER ;

CALL sales_for_month('2023-12-03');




CREATE VIEW seller_sales_tiers 
AS
SELECT s.id, s.seller_name, (CONCAT('$', FORMAT(SUM(o.order_quantity * (p.price*0.01)), 2))) AS total_sales_sum, 
(CASE WHEN SUM(o.order_quantity * (p.price/100)) >= 100000 THEN 'High'  WHEN SUM(o.order_quantity * (p.price/100)) >= 10000 AND SUM(o.order_quantity * (p.price/100)) < 100000 THEN 'Medium' ELSE 'Low' END) AS sales_tier
FROM sellers s
JOIN orders o ON s.id = o.seller_id
JOIN product p ON o.product_id = p.id
GROUP By s.id, s.seller_name
ORDER BY sales_tier, SUM(o.order_quantity * p.price);

SELECT * FROM seller_sales_tiers;


DELIMITER //
CREATE PROCEDURE top_products_for_seller (IN target_name VARCHAR(50))
BEGIN
	SELECT s.id AS seller_id, p.id AS product_id, p.product_name, CONCAT('$', FORMAT(SUM(o.order_quantity * (p.price*0.01)), 2)) AS total_sales 
    FROM sellers s
    JOIN orders o ON s.id = o.seller_id
    JOIN product p ON o.product_id = p.id
    WHERE s.seller_name = target_name 
    GROUP BY s.id, p.id, p.product_name
    ORDER BY SUM(o.order_quantity * p.price) DESC;
END //
DELIMITER ;

CALL top_products_for_seller('Bauch-Altenwerth');

DELIMITER //
CREATE PROCEDURE seller_running_totals (IN target_name VARCHAR(50))
BEGIN
	SELECT o.seller_id, o.order_id, o.order_date, CONCAT('$', FORMAT(o.order_quantity * (p.price*0.01), 2)) AS order_total, 
     CONCAT('$', FORMAT(SUM(o.order_quantity * (p.price*0.01)) OVER (PARTITION BY o.seller_id ORDER BY o.order_date), 2)) AS running_total
    FROM orders o
    JOIN sellers s ON o.seller_id = s.id
    JOIN product p ON o.product_id = p.id
    WHERE s.seller_name = target_name;
END //

DELIMITER ;

CALL seller_running_totals('Bauch-Altenwerth');



ALTER TABLE buyer ADD INDEX buyer_country_index (buyer_country);

ALTER TABLE buyer ADD INDEX buyer_name_index (first_name, last_name);

ALTER TABLE buyer ADD INDEX buyer_city_index (buyer_city);

ALTER TABLE orders ADD INDEX order_date_index (order_date);

ALTER TABLE orders ADD INDEX order_quantity_index (order_quantity);

ALTER TABLE sellers ADD INDEX seller_name_index (seller_name);

ALTER TABLE product ADD INDEX price_index (price);




