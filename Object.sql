-- Object.sql
-- This file contains functions and triggers to implement requirements

--------------- constraint ------------------------------- 
-- create trigger so that no one can modify UserID
CREATE TRIGGER TR_UserID_update ON Customer
FOR UPDATE AS
IF UPDATE(UserID)
BEGIN 
    RAISERROR ('UserID cannot change.', 16, 1);
    ROLLBACK
END 
GO

-- create trigger so that no one can modify Credit_Card_ID
CREATE TRIGGER TR_Credit_Card_ID_update ON CreditCard
FOR UPDATE AS
IF UPDATE(Credit_Card_ID)
BEGIN 
    RAISERROR ('CreditCardID cannot change.', 16, 1);
    ROLLBACK
END 
GO

-- create trigger so that no one can modify Product_id
CREATE TRIGGER TR_ProductID_update ON Product
FOR UPDATE AS
IF UPDATE(Product_id)
BEGIN 
    RAISERROR ('Product_id cannot change.', 16, 1);
    ROLLBACK
END 
GO

-- create trigger so that no one can modify Order_id
CREATE TRIGGER TR_OrderID_update ON ProductOrder
FOR UPDATE AS
IF UPDATE(Order_id)
BEGIN 
    RAISERROR ('Order_id cannot change.',16, 1);
    ROLLBACK
END 
GO


--------------- constraint ------------------------------- 
-- OrderItem.PaidPrice and Order.Total_Amount should always be calculated automatically
-- check constraint OrderItem.PaidPrice should always be greater or equal to Product.Cost_Price
-- create function
OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;

CREATE FUNCTION calculate_PaidPrice
(
	@Product_id VARCHAR(30)
)
RETURNS DECIMAL(10,2)
AS BEGIN
	DECLARE @PaidPrice DECIMAL(5,2)
	DECLARE @Cost_Price VARCHAR(30)
	SELECT @Cost_Price = CONVERT(VARCHAR, DecryptByKey(Cost_Price))FROM Product
	WHERE Product_id = @Product_id

	SELECT @PaidPrice = (1 - Discount) * Sales_Price 
	FROM Product
	WHERE Product_id = @Product_id
	
	-- check constraint OrderItem.PaidPrice should always be greater or equal to Product.Cost_Price
	RETURN
		CASE WHEN @PaidPrice >= @Cost_Price THEN @PaidPrice
	END
END
GO


ALTER TABLE OrderItem
   ADD PaidPrice AS dbo.calculate_PaidPrice(Product_id)
GO

SELECT * FROM OrderItem


-- Total amount should be calculated automatically
CREATE FUNCTION calculate_TotalAmount
(
@Orderid VARCHAR(30)
)
RETURNS DECIMAL(10,2)
AS BEGIN
	DECLARE @TotalAmount DECIMAL(10,2)
		
	SELECT @TotalAmount = SUM(Quantity * PaidPrice)
	FROM OrderItem oi
	JOIN
	ProductOrder po ON po.Order_id = oi.Order_id
	WHERE oi.Order_id = @Orderid
    GROUP BY oi.Order_id

	RETURN @TotalAmount
END
GO

ALTER TABLE ProductOrder
   ADD Total_Amount AS dbo.calculate_TotalAmount(Order_id)
GO

SELECT * FROM ProductOrder;

--------------- constraint ------------------------------- 
-- start charging credit card whenever order status is changed to shipped.
-- create trigger on ProductOrder table for update
CREATE TRIGGER TR_ProductOrder_ChargeCreditCardOnShipped_Update
ON ProductOrder
FOR UPDATE
AS
	OPEN SYMMETRIC KEY CreditCardNumberKey
	DECRYPTION BY CERTIFICATE CreditCardNumberCert;
	IF UPDATE(Status)
		BEGIN

			DECLARE @Credit_Card_Number VARCHAR(30)
			DECLARE @Order_id VARCHAR(30)
			DECLARE @Total_Amount DECIMAL(10,2)

			-- SUBSTRING(CONVERT(VARCHAR, DecryptByKey(Credit_Card_Number)) , 16, 4) 
			SELECT @Credit_Card_Number = CONVERT(VARCHAR, DecryptByKey(Credit_Card_Number)) 
			FROM CreditCard c JOIN
			ProductOrder p ON c.Credit_Card_ID = p.Credit_Card_ID
			WHERE p.Status = 'shipped'

			DECLARE @LastFourDigit VARCHAR(10)
			SELECT @LastFourDigit = SUBSTRING(@Credit_Card_Number, 16, 4)

			SELECT @Order_id = Order_id FROM ProductOrder WHERE Status = 'shipped'
			SELECT @Total_Amount = Total_Amount FROM ProductOrder WHERE Status = 'shipped'

			PRINT 'Credit Card ending with ' + @LastFourDigit + ' is charged $' + CAST(@Total_Amount AS NVARCHAR(100)) + ' for the order with order id ' + @Order_id		
		END 
GO


--------------- constraint ------------------------------- 
-- when order is placed, deduct OrderItem.Quantity from Product.Quantity for each order item
-- create trigger
CREATE TRIGGER TR_OrderItem_Quantity_Insert
ON OrderItem
FOR INSERT
AS
		DECLARE @OrderQuantity INT
		SELECT @OrderQuantity = inserted.Quantity FROM inserted

		UPDATE Product SET Quantity -= @OrderQuantity
		FROM inserted i JOIN Product p
		ON i.Product_id = p.Product_id
GO

--------------- constraint ------------------------------- 
-- when order item is removed, add OrderItem.Quantity back to Product.Quantity
-- create trigger
CREATE TRIGGER TR_OrderItem_Quantity_Delete
ON OrderItem
FOR DELETE
AS
	DECLARE @OrderQuantity INT
	SELECT @OrderQuantity = deleted.Quantity FROM deleted

	UPDATE Product SET Quantity += @OrderQuantity
	FROM deleted d JOIN Product p
	ON d.Product_id = p.Product_id
GO


--------------- Customer permission ------------------------------- 
-- customer can remove his credit card
-- create procedure
CREATE PROCEDURE removeCreditCardByCustomer
@Credit_Card_Number VARCHAR(20)
AS
	DECLARE @CreditNum  VARCHAR(30)
	SELECT @CreditNum = MAX(Credit_Card_ID) FROM CreditCard

	DELETE FROM CreditCard WHERE Credit_Card_ID = @CreditNum

	PRINT 'Credit card removed'
GO

-- customer can insert credit card
-- create procedure
CREATE PROCEDURE insertCreditCardByCustomer
@Credit_Card_Number VARCHAR(30),
@Holder_Name VARCHAR(30),
@Expire_Date DATE, 
@CVC_Code INT,
@Billing_Address VARCHAR(100)
AS
	 DECLARE @CR_CARD_NO VARBINARY(MAX)
	 SELECT @CR_CARD_NO = ENCRYPTBYKEY(KEY_GUID('CreditCardNumberKey'), @Credit_Card_Number)

	 DECLARE @CR_CARD_ID VARCHAR(30)
	 SELECT @CR_CARD_ID = MAX(Credit_Card_ID) FROM CreditCard

	 INSERT INTO CreditCard(Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code, Billing_Address, OwnerID)
	 VALUES (@CR_CARD_ID+1, @CR_CARD_NO, @Holder_Name, @Expire_Date, @CVC_Code, @Billing_Address, USER_NAME())

	 PRINT 'Credit card inserted'
GO

REVERT

-- customer can only update Holder name and Billing address of a credit card
-- create procedure
CREATE PROCEDURE updateCreditCardHolderNameByCustomer
@Credit_Card_Number VARCHAR(20),
@Holder_Name VARCHAR(30)
AS
	DECLARE @CreditNum  VARCHAR(30)
	SELECT @CreditNum = MAX(Credit_Card_ID) FROM CreditCard

	UPDATE CreditCard SET Holder_Name = @Holder_Name WHERE Credit_Card_ID = @CreditNum

	PRINT 'Holder name is updated'
GO


CREATE PROCEDURE updateCreditCardHBillingAddressByCustomer
@Credit_Card_Number VARCHAR(20),
@Billing_Address VARCHAR(100)
AS
	DECLARE @CreditNum  VARCHAR(30)
	SELECT @CreditNum = MAX(Credit_Card_ID) FROM CreditCard

	UPDATE CreditCard SET Billing_Address = @Billing_Address WHERE Credit_Card_ID = @CreditNum

	PRINT 'Billing address is updated'
GO


--------------- Customer service representative permission ------------------------------- 
-- can remove orderitem only if the order status is 'in preparation' 
-- create procedure that accepts Order_id which customer wants to remove from OrderItem

CREATE PROCEDURE removeOrderItemIfStatusInPreparation
@Order_id VARCHAR(30)
AS
	DECLARE @Status VARCHAR(30)
	SELECT @Status = Status FROM ProductOrder WHERE Order_id = @Order_id

		IF @Status = 'in preparation'
			DELETE FROM OrderItem WHERE Order_id = @Order_id
		ELSE 
			PRINT 'Order with Order id ' + @Order_id + ' cannot be deleted.'
GO


-- if the order doesn't contain order items then order should be removed
-- create procedure that removes order that has no order items.

CREATE PROCEDURE removeOrderIfNoOrderItemExist
AS
	DELETE FROM ProductOrder WHERE Order_id 
	NOT IN (SELECT Order_id FROM OrderItem)
GO

-- can update the quantity of an order item only if the order status is 'in preparation'
-- create procedure that update quantity if the order status is 'in preparation'
CREATE PROCEDURE updateOrderItemQuantityIfStatusInPreparation
@Order_id VARCHAR(30),
@Product_id VARCHAR(30),
@Quantity INT
AS
	DECLARE @Status VARCHAR(30)
	SELECT @Status = Status FROM ProductOrder WHERE Order_id = @Order_id

		IF @Status = 'in preparation'
			UPDATE OrderItem SET Quantity = @Quantity WHERE Order_id = @Order_id AND Product_id = @Product_id
		ELSE 
			PRINT 'Cannot update quantity of order item with order id ' + @Order_id
GO

-- can insert a new order item only if the order status is 'in preparation'
-- create a procedure
CREATE PROCEDURE insertNewOrderItemIfStatusInPreparation
@Order_id VARCHAR(30),
@Product_id VARCHAR(30),
@Quantity INT
AS
	DECLARE @Status VARCHAR(30)
	SELECT @Status = Status FROM ProductOrder WHERE Order_id = @Order_id

	IF @Status = 'in preparation'
			INSERT INTO OrderItem(Order_id, Product_id, Quantity) VALUES (@Order_id, @Product_id, @Quantity)
		ELSE 
			PRINT 'Cannot insert new order item to order with order id ' + @Order_id
GO


--------------- Sales permission----------------------------------
CREATE PROCEDURE insertProductBySales
@Name VARCHAR(30),
@Quantity INT,
@Description VARCHAR(30),
@Cost_Price VARBINARY(MAX),
@Sales_Price DECIMAL(5,2),
@Discount DECIMAL(4,2)
AS
	 DECLARE @Cost VARBINARY(MAX)
	 SELECT @Cost = ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), @Cost_Price)

	 DECLARE @Product_id VARCHAR(30)
	 SELECT @Product_id = MAX(Credit_Card_ID) FROM CreditCard

	 INSERT INTO Product(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
	 VALUES (@Product_id+1, @Name, @Quantity, @Description, @Cost, @Sales_Price, @Discount)

	 PRINT 'Product inserted'
GO

--------------- SalesManager permission ------------------------------- 
-- can remove product from database if its quantity is 0
-- create trigger that will allow to delete product having 0 quantity
CREATE TRIGGER TR_Product_Quantity_Delete
ON SalesManager_Product_view
INSTEAD OF DELETE
AS
	DECLARE @Quantity INT
	DECLARE @Product_id VARCHAR(30)

	SELECT @Product_id = Product_id from DELETED
	SELECT @Quantity = Quantity FROM DELETED;
	IF @Quantity = 0
		DELETE FROM Product WHERE Product_id = @Product_id 
	ELSE
		ROLLBACK
GO


