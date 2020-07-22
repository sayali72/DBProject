-- Testing.sql
-- This file contains all test cases to satisfy constraints and permission requirements

------------------------------------------ test cases to verify constraint ------------------------------------------

-- OrderItem.PaidPrice and Order.Total_Amount should always be calculated automatically
-- check constraint OrderItem.PaidPrice should always be greater or equal to Product.Cost_Price

-- below result shows that PaidPrice and Total_Amount is calculated automatically for each order OrderItem
-- and PaidPrice is always greater than its Cost_Price
OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;

SELECT * FROM Product;
SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

---------------------------------------------------------------------------------------------------------------------

-- creditCard should be charged whenever order status changes to 'shipped'
-- below statement fires a trigger than prints message stating that credit card has been charged with total amount 
OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;
UPDATE ProductOrder SET Status = 'shipped' WHERE Order_id = 'O12345';
SELECT * FROM ProductOrder
GO

---------------------------------------------------------------------------------------------------------------------

-- when order is placed, deduct OrderItem.Quantity from Product.Quantity for each order item
-- below statement (when order is placed) fires a trigger that deduct OrderItem.Quantity from Product.Quantity 

-- before placing the order for product 'P47554' (Juicer & Blender)
SELECT * FROM OrderItem;
SELECT * FROM ProductOrder;
SELECT * FROM Product; -- Quantity = 10

INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O45676', 'MikeNorman', '2019-04-18', '22225', '2200 Childrens Way Nashville, TN 37232', 'placed');
INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O45676', 'P47554', 3);

-- after placing the order with Order_id 'O45676' and product 'P47554' (Juicer & Blender)
SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;
SELECT * FROM Product; -- Quantity becomes 7

---------------------------------------------------------------------------------------------------------------------

-- when order item is removed, add OrderItem.Quantity back to Product.Quantity
-- below statement fires a trigger when order item is removed  
DELETE FROM OrderItem WHERE Order_id = 'O45676';

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;
SELECT * FROM Product; -- Quantity becomes 10 again for product 'P47554' (Juicer & Blender)

---------------------------------------------------------------------------------------------------------------------

-- no one can update UserID, Credit_Card_ID, Order_id and Product_id
-- below update statements should give an error
UPDATE Customer SET UserID = 'U0001' WHERE Firstname = 'Martin';

UPDATE CreditCard SET Credit_Card_ID = '22210' WHERE OwnerID = 'LindaSmith';

UPDATE Product SET Product_id = 'P25455' WHERE Name = 'Kitchen Dining Set';

UPDATE ProductOrder SET Order_id = 'O23465' WHERE Credit_Card_ID = '22222';

UPDATE ProductOrder SET Credit_Card_ID = '22229' WHERE Order_id = 'O24335';

UPDATE ProductOrder SET UserID = 'MikeNorman' WHERE Order_id = 'O24335';

---------------------------------------------------------------------------------------------------------------------

-- Password, credit_card_number, cost_price should be encrypted
SELECT * FROM Customer;

SELECT * FROM CreditCard;

SELECT * FROM Product;

revert
---------------------------------------------------------------------------------------------------------------------


------------------------------------------ test cases to verify CustomerRole permission ----------------------------
OPEN SYMMETRIC KEY PasswordKey
DECRYPTION BY CERTIFICATE PasswordCert;

OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;

EXECUTE AS USER = 'MartinTaylor';

-- can view information of all products except Cost_Price
SELECT * FROM Customer_Product_view;

-- can view their own information (Customer table)
-- here customer can view his password
SELECT * FROM Cust_Customer_view; 

-- should be able to update their own information (Customer)
-- here customer 'MartinTaylor' sees only his own record, which he can update via view
UPDATE Cust_Customer_view SET Email = 'martin.taylor123@gmail.com';
UPDATE Cust_Customer_view SET Firstname = 'Martin'; 
UPDATE Cust_Customer_view SET Lastname = 'T'; 
UPDATE Cust_Customer_view SET Address = '6500 Old Hickory Pkwy, Nashville, TN37654'; 
UPDATE Cust_Customer_view SET Phone = '656-345-4532'; 


-- view updated changes
OPEN SYMMETRIC KEY PasswordKey
DECRYPTION BY CERTIFICATE PasswordCert;
SELECT * FROM Cust_Customer_view; 

-- can view last 4 digit of Credit Card
SELECT * FROM Cust_CreditCard_view; -- should able to view his own credit card details (along with last 4 digit of card)

-- can insert a credit card
OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;
EXEC insertCreditCardByCustomer @Credit_Card_Number = '4656-7457-8464-8979', @Holder_Name = 'Martin T', @Expire_Date = '2025-09-05', 
@CVC_Code = 455, @Billing_Address = '5456 B Town Nashville, TN 37656';

-- view inserted card
OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;
SELECT * FROM Cust_CreditCard_view;

-- should be able to update Holder_Name of his own card
OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;
EXEC updateCreditCardHolderNameByCustomer @Credit_Card_Number = '4656-7457-8464-8979', @Holder_Name = 'John M';

-- should be able to update Billing_Adress of his own card 
EXEC updateCreditCardHBillingAddressByCustomer @Credit_Card_Number = '4656-7457-8464-8979', @Billing_Address = '3125 A Pkwy Murfreesboro, TN 37129';

-- view updated card
OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;
SELECT * FROM Cust_CreditCard_view;

-- can remove his own credit card
EXEC removeCreditCardByCustomer @Credit_Card_Number = '5463-1175-4647-8989';

CLOSE SYMMETRIC KEY CreditCardNumberKey;
CLOSE SYMMETRIC KEY PasswordKey;

REVERT

------------------------------------------ test cases to verify CustomerServiceRepresentativeRole permission --------------------------------
EXECUTE AS USER = 'CustomerServiceRepresentative1';

-- can view information of all products except Cost_Price
SELECT * FROM Customer_Product_view;

-- can view Customer information and Orders
SELECT * FROM CustomerServiceRepresentative_Customer_view;
SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

-- can remove order item if the order status is 'in preparation'
-- execute REVERT
UPDATE ProductOrder SET Status = 'in preparation' WHERE Order_id = 'O24335';

-- should be able to remove order item as status = 'in preparation'
EXEC removeOrderItemIfStatusInPreparation @Order_id = 'O24335'; 

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

-- should NOT be able to remove orderitem as status = 'placed'
EXEC removeOrderItemIfStatusInPreparation @Order_id = 'O12345'; 

-- if the order doesn't contain order items then order should be removed
-- insert sample order in to ProductOrder table
-- execute REVERT
INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O33333', 'LindaSmith', '2019-04-21', '22224', '4544 Church St Nashville, TN 37246', 'placed');
INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O44444', 'MikeNorman', '2019-04-21', '22225', '5890 Old Fort Ln Murfreesboro, TN 37246', 'placed');

-- this procedure removes all the orders from ProductOrder table that does not exist in OrderItem table
EXEC removeOrderIfNoOrderItemExist;

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

-- can update the quantity of an orderitem only if the order status is 'in preparation'
-- insert sample test data
-- execute REVERT
INSERT INTO ProductOrder(Order_id, UserID, Order_Date, Credit_Card_ID, Shipping_address, Status)
VALUES('O33333', 'LindaSmith', '2019-04-21', '22224', '4544 Church St Nashville, TN 37246', 'in preparation');
INSERT INTO OrderItem(Order_id, Product_id, Quantity)
VALUES('O33333', 'P54638', 1);


-- should be able to update quantity of order item as status = 'in preparation'
EXEC updateOrderItemQuantityIfStatusInPreparation @Order_id = 'O33333', @Product_id = 'P54638', @Quantity = 2;

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

-- should NOT be able to update quantity of orderitem as status = 'placed'
EXEC updateOrderItemQuantityIfStatusInPreparation @Order_id = 'O12345', @Product_id = 'P47474', @Quantity = 3;

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

-- can insert a new order item to a placed order only if the order status is 'in preparation'
-- should be able to insert new order item as status = 'in preparation'
EXEC insertNewOrderItemIfStatusInPreparation @Order_id = 'O33333', @Product_id = 'P35333', @Quantity = 1;

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem; -- now Order 'O33333' contains two products

-- should NOT be able to insert new order item as status = 'placed'
EXEC insertNewOrderItemIfStatusInPreparation @Order_id = 'O12345', @Product_id = 'P47474', @Quantity = 2;

SELECT * FROM ProductOrder;
SELECT * FROM OrderItem;

REVERT

------------------------------------------ test cases to verify SalesRole permission --------------------------------
OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;

EXECUTE AS USER = 'Sales1';

-- can select Product table via view
SELECT * FROM Sales_Product_view;

-- can insert into product table via procedure
EXEC insertProductBySales @Name = 'Mobile Cover', @Quantity = 4, @Description  ='Mobile Cover', @Cost_Price = 16.00, @Sales_Price = 22.00, @Discount = 0.05;

-- can update Product table except Cost_Price, Sales_Price and Discount
UPDATE Sales_Product_view SET Quantity = 5 WHERE Product_id = 'P35333'; -- should be able to update
UPDATE Sales_Product_view SET Cost_Price = 10.00 WHERE Product_id = 'P35333'; -- should NOT be able to update
UPDATE Sales_Product_view SET Sales_Price = 25.00 WHERE Product_id = 'P35333'; -- should NOT be able to update
UPDATE Sales_Product_view SET Discount = 0.1 WHERE Product_id = 'P35333'; -- should NOT be able to update

REVERT

------------------------------------------- test cases to verify SalesManagerRole permission---------------------------------
OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;
EXECUTE AS USER = 'SalesManager1';

-- can select Product table via view
SELECT * FROM SalesManager_Product_view;

-- can insert into product table via procedure 
EXEC insertProductBySales @Name = 'Mobile Cover', @Quantity = 4, @Description  ='Mobile Cover', @Cost_Price = 16.00, @Sales_Price = 22.00, @Discount = 0.05;


-- can update product table including Cost_Price, Sales_Price, Discount via view
UPDATE SalesManager_Product_view SET Quantity = 0 WHERE Product_id = '22227'; 
UPDATE SalesManager_Product_view SET Cost_Price = 10.00 WHERE Product_id = '22227'; 
UPDATE SalesManager_Product_view SET Sales_Price = 25.00 WHERE Product_id = '22227'
UPDATE SalesManager_Product_view SET Discount = 0.1 WHERE Product_id = '22227';

-- can remove a product only if its quantity is 0 via trigger on view 
DELETE FROM SalesManager_Product_view WHERE Product_id = '22227'; -- will be removed as the qunaity is 0
DELETE FROM SalesManager_Product_view WHERE Product_id = 'P54638'; -- will NOT be removed as the qunaity is NOT 0

-- no permission on all other table
SELECT * FROM Customer; -- should NOT be allowed
SELECT * FROM CreditCard; -- should NOT be allowed
SELECT * FROM ProductOrder; -- should NOT be allowed
SELECT * FROM OrderItem; -- should not NOT allowed

REVERT

------------------------------------------- test cases to verify OrderProcessorsRole permission---------------------------------
EXECUTE AS USER = 'OrderProcessors1';

-- can view Order excluding Total_Amount and Credit_Card_ID
SELECT * FROM OrderProcessors_Order_view;

-- can view OrderItem excluding PaidPrice
SELECT * FROM OrderProcessors_OrderItem_view;

-- can only update status attribute of ProductOrder via procedure 
UPDATE OrderProcessors_Order_view SET Status = 'shipped' WHERE Order_id = 'O12345'; -- should be able to update
UPDATE OrderProcessors_Order_view SET Shipping_address = '2211 Old Fort Pkwy Nashville, TN 37156' WHERE Order_id = 'O12345'; -- should NOT be able to update

REVERT



------------------------------------- insert and update sample test data for audit --------------------------------------------
OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;

EXECUTE AS USER = 'Sales1';
EXEC insertProductBySales @Name = 'Audit product 1', @Quantity = 20, @Description  ='Audit product 1', @Cost_Price = 20.00, @Sales_Price = 40.00, @Discount = 0.05;
UPDATE Sales_Product_view SET Quantity = 13 WHERE Product_id = '22227'; 
REVERT


EXECUTE AS USER = 'SalesManager1'
UPDATE SalesManager_Product_view SET Sales_Price = 25.00 WHERE Product_id = '22227'; 
UPDATE SalesManager_Product_view SET Discount = 0.05 WHERE Product_id = 'P23531'; 
UPDATE SalesManager_Product_view SET Description = 'Kitchen Dining Set - pack(2)' WHERE Product_id = 'P35333'; 
REVERT

SELECT * FROM PRODUCT;
SELECT * FROM ProductSecurityAudit;

DELETE FROM Product WHERE Product_id = '22227'
