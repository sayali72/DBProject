# DBProject for an e-commerce website

A new dot name company has decided to launch their new e-commerce website. The company has hired you as a database specialist to design and develop a database system to support the online shopping business. After several interviews with stakeholder you come up with following tables.

Customer (UserID, Email, Password, Firstname, Lastname, Address, Phone)
CreditCard (Credit_Card_ID, Credit_Card_Number, Holder_Name, Expire_Date, CVC_Code,
Billing_Address, OwnerID) where OwnerID refers to Customer.UserID.

Product(Product id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount)
Where discount on the product is like 5%, 10% or 20% off. User needs to pay (1-
Discount)*Sales_Price for the product.

Order(Order id, UserID, Order_Date, Total_Amount, Credit_Card_ID, Shipping_address, Status)
(UserID, Credit_Card_ID) is one foreign key, referenceing CreditCart(Credit_Card_ID,
OwnerID)

Status must be a value from {placed, in preparation, ready to ship, shipped}
Total_Amount of money is the money the user needs to pay, excluding tax and shipping,
for the order. It is a derived value by summing Quantity*PaidPrice of all items in the
order.

OrderItem(Order id, Product id, PaidPrice, Quantity)
PaidPrice is calculated from Sales price and Discount of the product when the order is
placed.

![](ERD.png)
