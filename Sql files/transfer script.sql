CREATE TABLE denormalized (
    orderid INT,
    order_quantity INT,
    seller_id INT,
    product_id INT,
    product_price INT,
    product_name VARCHAR(255),
    buyer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(255),
    country VARCHAR(255),
    cc_number varchar(255),
    cc_exp varchar(255),
    review VARCHAR(255),
    rating varchar(255),
    seller_name VARCHAR(255),
    seller_country VARCHAR(255),
    order_date VARCHAR(255)
);









/*SET GLOBAL local_infile = true;
LOAD DATA LOCAL INFILE 'C:\\Users\\jedna\\Downloads\\denormalized_orders\\denormalized_orders_24020560.csv'
INTO TABLE denormalized
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;*/