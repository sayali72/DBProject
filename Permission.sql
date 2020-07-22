-- Permission.sql
-- This file contains SQL statements to create logins/users/roles
-- and statements to grant/revoke/deny permissions

-- create sql login and users from sql login
CREATE LOGIN C01L WITH PASSWORD = 'C01'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER Sales1 FROM LOGIN C01L;

CREATE LOGIN C02L WITH PASSWORD = 'C02'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER SalesManager1 FROM LOGIN C02L;

CREATE LOGIN C03L WITH PASSWORD = 'C03'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER OrderProcessors1 FROM LOGIN C03L;

CREATE LOGIN C04L1 WITH PASSWORD = 'C04'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER MartinTaylor FROM LOGIN C04L1;

CREATE LOGIN C04L2 WITH PASSWORD = 'C04'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER LindaSmith FROM LOGIN C04L2;

CREATE LOGIN C04L3 WITH PASSWORD = 'C04'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER MikeNorman FROM LOGIN C04L3;

CREATE LOGIN C05L WITH PASSWORD = 'C05'
MUST_CHANGE, CHECK_EXPIRATION = ON;

CREATE USER CustomerServiceRepresentative1 FROM LOGIN C05L;


-- create roles, add member to roles
CREATE ROLE CustomerRole;
ALTER ROLE CustomerRole ADD MEMBER MartinTaylor;
ALTER ROLE CustomerRole ADD MEMBER LindaSmith;
ALTER ROLE CustomerRole ADD MEMBER MikeNorman;

CREATE ROLE CustomerServiceRepresentativeRole;
ALTER ROLE CustomerServiceRepresentativeRole ADD MEMBER CustomerServiceRepresentative1;

CREATE ROLE SalesRole;
ALTER ROLE SalesRole ADD MEMBER Sales1;

CREATE ROLE SalesManagerRole;
ALTER ROLE SalesManagerRole ADD MEMBER SalesManager1;

CREATE ROLE OrderProcessorsRole;
ALTER ROLE OrderProcessorsRole ADD MEMBER OrderProcessors1;

---------------- permission to CustomerRole --------------------------

-- can view information of all products except Cost_Price
-- deny access to base table Product and grant access to view 
DENY SELECT ON Product TO CustomerRole;
GRANT SELECT ON Customer_Product_view TO CustomerRole;


-- can view and update their own information (Customer table)
-- deny access to base table and grant access to Customer view 
DENY SELECT, UPDATE ON Customer TO CustomerRole;
GRANT SELECT, UPDATE ON Cust_Customer_view TO CustomerRole;


-- can view last 4 digit of Credit Card
-- can insert/remove credit card, can only update Holder_Name and Billing_Address
-- deny access to base table and grant access to CreditCard view 
DENY SELECT, INSERT, UPDATE, DELETE ON CreditCard TO CustomerRole;
GRANT SELECT ON Cust_CreditCard_view TO CustomerRole;

-- grant access to procedure through which customer can REMOVE credit card
GRANT EXECUTE ON removeCreditCardByCustomer TO CustomerRole;

-- grant access to procedure through which customer can INSERT credit card
GRANT EXECUTE ON insertCreditCardByCustomer TO CustomerRole;

-- grant access to procedure through which customer can UPDATE ONLY Holder_Name and Billing_Address
GRANT EXECUTE ON updateCreditCardHolderNameByCustomer TO CustomerRole;
GRANT EXECUTE ON updateCreditCardHBillingAddressByCustomer TO CustomerRole;

GRANT CONTROL ON SYMMETRIC KEY::PasswordKey TO CustomerRole;  
GRANT CONTROL ON SYMMETRIC KEY::CreditCardNumberKey TO CustomerRole;  
GRANT CONTROL ON SYMMETRIC KEY::CostPriceKey TO CustomerRole;  

GRANT CONTROL ON CERTIFICATE::PasswordCert TO CustomerRole;
GRANT CONTROL ON CERTIFICATE::CreditCardNumberCert TO CustomerRole;
GRANT CONTROL ON CERTIFICATE::CostPriceCert TO CustomerRole;

---------------- permission to CustomerServiceRepresentativeRole --------------------------

-- can view information of all products except Cost_Price
-- deny access to base table Product and grant access to view 
DENY SELECT ON Product TO CustomerServiceRepresentativeRole;
GRANT SELECT ON Customer_Product_view TO CustomerServiceRepresentativeRole;

-- can view Customer information and Orders
-- deny access on base table Customer and grant access via view
DENY SELECT ON Customer TO CustomerServiceRepresentativeRole;
GRANT SELECT ON CustomerServiceRepresentative_Customer_view TO CustomerServiceRepresentativeRole;
GRANT SELECT ON ProductOrder TO CustomerServiceRepresentativeRole;
GRANT SELECT ON OrderItem TO CustomerServiceRepresentativeRole;

-- can remove orderitem only if the order status is 'in preparation' 
-- grant execute on procedure 
-- CustomerServiceRepresentative can only insert, update, delete through a procedure
GRANT EXECUTE ON removeOrderItemIfStatusInPreparation TO CustomerServiceRepresentativeRole;

-- if the order doesn't contain order items then order should be removed
-- grant execute on procedure 
GRANT EXECUTE ON removeOrderIfNoOrderItemExist TO CustomerServiceRepresentativeRole;

-- can update the qunatity of an orderitem only if the order status is 'in preparation'
-- grant execute on procedure
GRANT EXECUTE ON updateOrderItemQuantityIfStatusInPreparation TO CustomerServiceRepresentativeRole;

-- can update the quantity of an orderitem only if the order status is 'in preparation'
-- grant execute on procedure
GRANT EXECUTE ON insertNewOrderItemIfStatusInPreparation TO CustomerServiceRepresentativeRole;


---------------- permission to SalesRole --------------------------
-- can select/insert/update Product table
DENY SELECT, INSERT, UPDATE ON Product TO SalesRole;
GRANT SELECT, UPDATE ON Sales_Product_view TO SalesRole;

GRANT EXECUTE ON insertProductBySales TO SalesRole;

-- cannot modify Cost_Price, Sales_Price and Discount 
DENY UPDATE ON OBJECT::Sales_Product_view(Cost_Price, Sales_Price, Discount) TO SalesRole;

GRANT CONTROL ON SYMMETRIC KEY::CostPriceKey TO SalesRole;  
GRANT CONTROL ON CERTIFICATE::CostPriceCert TO SalesRole;

---------------- permission to SalesManagerRole --------------------
-- can select/insert/update Product table including Cost_Price, Sales_Price, Discount
DENY SELECT, INSERT, UPDATE, DELETE ON Product TO SalesManagerRole;

GRANT SELECT, UPDATE, DELETE ON SalesManager_Product_view TO SalesManagerRole;

GRANT EXECUTE ON insertProductBySales TO SalesManagerRole;

-- can remove product from database if its quantity is 0
-- deny delete permission on product
DENY DELETE ON Product TO SalesManagerRole;

-- no permission on all other tables
DENY SELECT, INSERT, UPDATE, DELETE ON Customer to SalesManagerRole;
DENY SELECT, INSERT, UPDATE, DELETE ON CreditCard to SalesManagerRole;
DENY SELECT, INSERT, UPDATE, DELETE ON ProductOrder to SalesManagerRole;
DENY SELECT, INSERT, UPDATE, DELETE ON OrderItem to SalesManagerRole;

GRANT CONTROL ON SYMMETRIC KEY::CostPriceKey TO SalesManagerRole;  
GRANT CONTROL ON CERTIFICATE::CostPriceCert TO SalesManagerRole;

---------------- permission to OrderProcessorsRole -----------------

-- can view Order excluding Total_Amount and Credit_Card_ID
-- deny permission on base table ProductOrder and grant select on view
DENY SELECT ON ProductOrder TO OrderProcessorsRole;
GRANT SELECT ON OrderProcessors_Order_view TO OrderProcessorsRole;

-- can view OrderItem excluding PaidPrice
-- deny permission on base table OrderItem and grant select on view
DENY SELECT ON OrderItem TO OrderProcessorsRole;
GRANT SELECT ON OrderProcessors_OrderItem_view TO OrderProcessorsRole;

-- can only update status attribute of ProductOrder
GRANT UPDATE ON OrderProcessors_Order_view (Status) TO OrderProcessorsRole;
GRANT CONTROL ON SYMMETRIC KEY::CreditCardNumberKey TO OrderProcessorsRole;  
GRANT CONTROL ON CERTIFICATE::CreditCardNumberCert TO OrderProcessorsRole;

