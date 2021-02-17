/* PARTE 2 */
/*1.Create the corresponding database using DDL  */

CREATE DATABASE ONLINE_SHOES_SALE;
USE ONLINE_SHOES_SALE;

/*2.Create all the necessary tables identified above using DDL */

CREATE TABLE ONLINESHOP(
	shopId INTEGER NOT NULL UNIQUE,
    shopName VARCHAR(20),
    email VARCHAR(20),
    phone VARCHAR(15),
    PRIMARY KEY(shopId)
);
ALTER TABLE ONLINESHOP MODIFY email VARCHAR(255);
ALTER TABLE ONLINESHOP MODIFY phone VARCHAR(20);

CREATE TABLE CUSTOMER(
	customer_id INTEGER NOT NULL UNIQUE,
    customer_name VARCHAR(30),
    address VARCHAR(60),
    phone VARCHAR(15),
    email VARCHAR(20),
    shopId INTEGER,
    PRIMARY KEY(customer_id),
    FOREIGN KEY (shopId)
		REFERENCES ONLINESHOP(shopId)
);

CREATE TABLE SUPPLIER(
	supplier_id INTEGER NOT NULL UNIQUE,
    supplier_name VARCHAR(30),
    address VARCHAR(60),
    phone VARCHAR(15),
    email VARCHAR(20),
    shopId INTEGER,
    PRIMARY KEY(supplier_id),
    FOREIGN KEY(shopId)
		REFERENCES ONLINESHOP(shopID)
);
ALTER TABLE SUPPLIER MODIFY email VARCHAR(255);

CREATE TABLE SHOES(
	product_id INTEGER NOT NULL UNIQUE,
    shoes_type VARCHAR(10),
    brand VARCHAR(10),
    size INTEGER,
    shoes_description VARCHAR(255),
    price DECIMAL,
    supplier_id INTEGER,
    shopId INTEGER,
    total_stock INTEGER,
    PRIMARY KEY(product_id),
    FOREIGN KEY(supplier_id)
		REFERENCES SUPPLIER(supplier_id),
    FOREIGN KEY(shopId)
		REFERENCES ONLINESHOP(shopID)
);

CREATE TABLE COURIER(
	courier_id INTEGER NOT NULL UNIQUE,
    courier_name VARCHAR(20),
    address VARCHAR(60),
    phone VARCHAR(15),
    email VARCHAR(20),
    PRIMARY KEY(courier_id)
);

CREATE TABLE SHOES_ORDER(
	order_id INTEGER NOT NULL UNIQUE,
    order_date date,
    customer_id INTEGER,
    courier_id INTEGER,
    PRIMARY KEY(order_id),
    FOREIGN KEY(customer_id) REFERENCES CUSTOMER(customer_id),
    FOREIGN KEY(courier_id) REFERENCES COURIER(courier_id)
);

CREATE TABLE LINE_ITEMS(
	line_number INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    product_id INTEGER,
    unit_price DECIMAL,
    quantity INTEGER,
    total DECIMAL,
    PRIMARY KEY(line_number),
    FOREIGN KEY(order_id) REFERENCES SHOES_ORDER(order_id),
    FOREIGN KEY(product_id) REFERENCES SHOES(product_id)
);


/* 3.	Populate at least three of your tables with some data using DML (insert into statement)
4.	Populate your database with a large data set representing a one-year transaction (01/01/2020 - 31/12/2020)
 on each table.  (Use online data generators such as Mockaroo or generate data to generate synthetic data.)
*/

INSERT INTO ONLINESHOP(shopId,shopName,email,phone)
VALUES(1,"THEBESTSHOES","thebestshoes@gmaiL","+353 083-222-3333");

INSERT INTO COURIER(courier_id,courier_name,address,phone,email)
VALUES(1425,"UPS", "080 Warner Pass", "803-217-8593", "skienl9@illinois.edu");

INSERT INTO COURIER(courier_id,courier_name,address,phone,email)
VALUES(1457,"AN POST", "O'connel Street", "(01) 705 7600", "care@anpostmobile.ie");

INSERT INTO COURIER(courier_id,courier_name,address,phone,email)
VALUES(2105,"Fedex", "9 Elgar Road", "165-162-5948", "btidball2@oracle.com");

INSERT INTO SUPPLIER(supplier_id,supplier_name,address,phone,email,shopId)
VALUES(1348,"NIKE","Westend Retail Park Unit 6, Blanchardstown, Dublin", "(01) 811 1140","nike@nike.com.ie",1);

INSERT INTO SUPPLIER(supplier_id,supplier_name,address,phone,email,shopId)
VALUES(1349,"MYSHOES","North Retail Park Unit 8, Blanchardstown, Dublin", "(01) 111 444","myshoes@myshoes.com.ie",1);

INSERT INTO SUPPLIER(supplier_id,supplier_name,address,phone,email,shopId)
VALUES(1350,"THEBESTSHOES","City West, Dublin", "(01) 324 1248","thebest@thebest.com.ie",1);


/* PARTE 3 */
/* 1.	Show all the details of the products that have a price greater than 100.*/
SELECT * FROM SHOES WHERE price > 100;

/* 2. Show all the products along with the supplier detail who supplied the products. */
SELECT SHOES.shoes_type, SUPPLIER.supplier_name, SUPPLIER.address,SUPPLIER.phone,SUPPLIER.email
FROM SHOES LEFT JOIN 
SUPPLIER ON SHOES.supplier_id = SUPPLIER.supplier_id;

/* 3.Create a stored procedure that takes the start and end dates of the sales and display all
 the sales transactions between the start and the end dates. */
DELIMITER //

CREATE PROCEDURE GetSales()
BEGIN
	SELECT shoes_order.order_date, product_id,unit_price,quantity,total
    FROM line_items
    LEFT JOIN shoes_order
    ON shoes_order.order_id = line_items.order_id
    WHERE order_date >= '2020-01-01' 
    AND order_date <= '2020-12-31' ORDER BY order_date DESC;
END //

DELIMITER ;
CALL GetSales();

/*4.Create a view that shows the total number of items a customer buys from the business
 in October 2020 along with the total price (use group by)*/
CREATE VIEW sales_per_customer_october AS
	select shoes_order.customer_id, shoes_order.order_date, sum(quantity), sum(total)
    from line_items
    left join shoes_order on line_items.order_id = shoes_order.order_id
    where order_date >= '2020-10-01' and order_date <= '2020-10-30'
    group by quantity;
SELECT * FROM sales_per_customer_october;

/*5. Create a trigger that adjusts the stock level every time a product is sold.*/

DELIMITER $$
 CREATE TRIGGER Stock_Update 
 AFTER INSERT ON ONLINE_SHOES_SALE.LINE_ITEMS
 FOR EACH ROW 
  BEGIN 
    UPDATE SHOES 
      SET SHOES.Total_Stock = SHOES.Total_Stock - New.Quantity 
    WHERE SHOES.product_id = New.product_id;
  END$$
DELIMITER ;

/* 6.Create a report of the annual sales (2020) of the business showing 
the total number of products sold and the total price sold every month  */

CREATE VIEW sales_per_month AS
	SELECT MONTH(shoes_order.order_date) as months,sum(quantity) as quantity,sum(total) as total
	FROM LINE_ITEMS
	INNER JOIN SHOES_ORDER
	ON shoes_order.order_id = line_items.order_id
	GROUP BY MONTH(order_date) with rollup
	ORDER BY MONTH(order_date) ASC;
     
SELECT * FROM sales_per_month;
   
/* 7.Display the growth in sales/services (as a percentage) for your business, from the 1st month of opening until now. */
SELECT total,
if (@last_total = 0, 0, ((total - @last_total) / total) * 100) "growth rate %", @last_total := total                  
from
	  (select @last_total := 0) x, (select total from sales_per_month) y;

/*8.Delete all customers who never buy a product from the business */
SET SQL_SAFE_UPDATES = 1;

DELETE FROM customer
WHERE NOT EXISTS (
    SELECT *
    FROM shoes_order
    WHERE customer_id = customer.customer_id
)