-- Schema.sql
-- This file contains create table statements, views and insert test data
-- *Note: columns ProductOrder.Total_Amount and OrdeItem.PaidPrice are added in table after creating a function present in Object.sql
-- Run Encrypt.sql before inserting test data to generate certificate and key


CREATE TABLE Customer
(
UserID VARCHAR(30) PRIMARY KEY,
Email VARCHAR(30),
Password VARBINARY(MAX),
Firstname VARCHAR(30),
Lastname VARCHAR(30),
Address VARCHAR(100),
Phone VARCHAR(15)
);

OPEN SYMMETRIC KEY PasswordKey
DECRYPTION BY CERTIFICATE PasswordCert;

-- insert test data into Customer table
INSERT INTO Customer(UserID, Email, Password, Firstname, Lastname, Address, Phone)
VALUES('MartinTaylor', 'martin.taylor@yahoo.com', ENCRYPTBYKEY(KEY_GUID('PasswordKey'), CONVERT(VARBINARY, 'Password@11111')), 'Martin', 'Taylor', '501 Broadway Nashville, TN 37203', '615-674-5543');

INSERT INTO Customer(UserID, Email, Password, Firstname, Lastname, Address, Phone)
VALUES('LindaSmith', 'linda.smith@gmail.com', ENCRYPTBYKEY(KEY_GUID('PasswordKey'), CONVERT(VARBINARY, 'Password@11112')), 'Linda', 'Smith', '424 Church Street Nashville, TN 372193', '624-867-8868');

INSERT INTO Customer(UserID, Email, Password, Firstname, Lastname, Address, Phone)
VALUES('MikeNorman', 'mike.norman@gmail.com', ENCRYPTBYKEY(KEY_GUID('PasswordKey'), CONVERT(VARBINARY, 'Password@11113')), 'Mike', 'Norman', '2200 Childrens Way Nashville, TN 37232', '653-868-9987');


SELECT * FROM Customer;


CREATE TABLE CreditCard
(
Credit_Card_ID VARCHAR(30),
Credit_Card_Number VARBINARY(MAX),
Holder_Name VARCHAR(30),
Expire_Date DATE,
CVC_Code INT,
Billing_Address VARCHAR(100), 
OwnerID VARCHAR(30),
PRIMARY KEY(Credit_Card_ID, OwnerID),
FOREIGN KEY (OwnerID) REFERENCES Customer(UserID)
);

OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;

-- insert test data into CreditCard table
INSERT INTO CreditCard(Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, OwnerID)
VALUES('22222', ENCRYPTBYKEY(KEY_GUID('CreditCardNumberKey'), CONVERT(VARBINARY, '4543-7647-6423-6410')), 'Martin S Taylor', '2023-05-15', 765, '501 Broadway Nashville, TN 37203', 'MartinTaylor');

INSERT INTO CreditCard(Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, OwnerID)
VALUES('22226', ENCRYPTBYKEY(KEY_GUID('CreditCardNumberKey'), CONVERT(VARBINARY, '3454-4467-3123-9908')), 'MartinMM', '2029-06-05', 142, '3422 MN Pkwy, TN 37123', 'MartinTaylor');

INSERT INTO CreditCard(Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, OwnerID)
VALUES('22224', ENCRYPTBYKEY(KEY_GUID('CreditCardNumberKey'), CONVERT(VARBINARY, '4567-3548-9204-5410')), 'Linda S', '2025-04-29', 453, '424 Church Street Nashville, TN 37219', 'LindaSmith');

INSERT INTO CreditCard(Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, OwnerID)
VALUES('22225', ENCRYPTBYKEY(KEY_GUID('CreditCardNumberKey'), CONVERT(VARBINARY, '8476-3719-8745-2090')), 'Mike Norman', '2027-06-13', 309, '2200 Childrens Way Nashville, TN 37232', 'MikeNorman');

SELECT * FROM CreditCard;


CREATE TABLE Product
(
Product_id VARCHAR(30) PRIMARY KEY, 
Name VARCHAR(30), 
Quantity INT, 
Description VARCHAR(100), 
Cost_Price VARBINARY(MAX), 
Sales_Price DECIMAL (5, 2),
Discount DECIMAL (4, 2) CHECK (Discount IN ('0.05','0.1','0.2'))
);

OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;

-- insert test data into Product table
INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
VALUES('P23531', 'Amazon Echo Show', 5, 'Amazon Echo Show', ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), 75.00)), 100, 0.1);

INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
VALUES('P35333', 'Kitchen Dining Set', 4, 'Kitchen Dining Set', ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), 200.00)), 350, 0.05);

INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
VALUES('P47474', 'Floor Lamp', 4, 'Floor lamp', ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), 55.00)), 75, 0.2);

INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
VALUES('P47554', 'Juicer & Blender', 8, 'Juicer & Blender', ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), 150.00)), 275, 0.1);

INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
VALUES('P56387', 'Garden Tools', 10, 'Garden Tools', ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), 17.00)), 30, 0.2);

INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
VALUES('P54638', 'Home Furniture', 30, 'Home Furniture', ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), 450.00)), 650, 0.05);


SELECT * FROM Product;


CREATE TABLE ProductOrder
(
Order_id VARCHAR(30),
UserID VARCHAR(30),
Order_Date DATE, 
Credit_Card_ID VARCHAR(30), 
Shipping_address VARCHAR(100),
Status VARCHAR(30) CHECK (Status IN ('placed', 'in preparation', 'ready to ship', 'shipped')),
PRIMARY KEY(Order_id),
FOREIGN KEY(Credit_Card_ID, UserID) REFERENCES CreditCard(Credit_Card_ID, OwnerID)
);

-- insert test data into ProductOrder table
INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O12345', 'MartinTaylor', '2019-04-21', '22222', '501 Broadway Nashville, TN 37203', 'placed');

INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O24335', 'LindaSmith', '2019-04-17', '22224', '1214 Church St Ste 100 Nashville, TN 37246', 'placed');

INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O56579', 'MikeNorman', '2019-04-18', '22225', '2200 Childrens Way Nashville, TN 37232', 'placed');


SELECT * FROM ProductOrder;


CREATE TABLE OrderItem
(
Order_id VARCHAR(30), 
Product_id VARCHAR(30),  
Quantity INT,
PRIMARY KEY(Order_id, Product_id),
FOREIGN KEY(Order_id) REFERENCES ProductOrder(Order_id),
FOREIGN KEY(Product_id) REFERENCES Product(Product_id)
);

-- insert test data into OrderItem
INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O12345', 'P23531', 1);

INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O24335', 'P47474', 5);

INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O24335', 'P54638', 2);

INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O56579', 'P54638', 1);

INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O56579', 'P47474', 5);

INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O56579', 'P35333', 2);


SELECT * FROM OrderItem;


-- view for SalesManagerRole on Product
CREATE VIEW SalesManager_Product_view 
AS
SELECT * FROM Product
GO

SELECT * FROM SalesManager_Product_view;


-- view for OrderProcessorsRole on ProductOrder
CREATE VIEW OrderProcessors_Order_view 
AS
SELECT Order_id, UserID, Order_date, Shipping_address, Status FROM ProductOrder
GO

SELECT * FROM OrderProcessors_Order_view;


-- view for OrderProcessorsRole on OrderItem
CREATE VIEW OrderProcessors_OrderItem_view 
AS
SELECT Order_id, Product_id, Quantity FROM OrderItem
GO

SELECT * FROM OrderProcessors_OrderItem_view;


-- view for CustomerRole on Product
CREATE VIEW Customer_Product_view 
AS 
SELECT Product_id, Name, Quantity, Description, Sales_Price, Discount
FROM Product
GO

SELECT * FROM Customer_Product_view;


-- view for CustomerRole on Customer
CREATE VIEW Cust_Customer_view 
AS 
SELECT Email, CONVERT(VARCHAR, DecryptByKey(Password)) AS 'Password', Firstname, Lastname, Address, Phone
FROM Customer WHERE UserID = USER_NAME()
GO

SELECT * FROM Cust_Customer_view;


-- view for CustomerRole on CreditCard 
CREATE VIEW Cust_CreditCard_view AS 
SELECT SUBSTRING(CONVERT(VARCHAR, DecryptByKey(Credit_Card_Number)) , 16, 4) AS Credit_Card_Number,
Holder_Name, Expire_Date, CVC_Code, Billing_Address FROM CreditCard cc
JOIN Customer c ON cc.OwnerID = c.UserID WHERE UserID = USER_NAME()
GO

SELECT * FROM Cust_CreditCard_view;


-- view for CustomerServiceRepresentativeRole to view customer information
CREATE VIEW CustomerServiceRepresentative_Customer_view 
AS 
SELECT UserID, Email, Password, Firstname, Lastname, Address, Phone
FROM Customer
GO

SELECT * FROM CustomerServiceRepresentative_Customer_view;

-- view for SalesRole to view Product information
CREATE VIEW Sales_Product_view 
AS 
SELECT Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount
FROM Product
GO

SELECT * FROM Sales_Product_view;