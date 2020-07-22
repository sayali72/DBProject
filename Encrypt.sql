-- Encrypt.sql
-- This file contains statements to encrypt the data


-- create database master key which is a symmetric key that will be used to protect the private keys of certificates 
-- and asymmetric key present in the database
CREATE MASTER KEY ENCRYPTION BY
PASSWORD = 'Password123'
GO

-- create a certificate to protect encryption key , which will be used to encrypt data in the database
CREATE CERTIFICATE PasswordCert
WITH SUBJECT = 'Protect password'
GO

CREATE CERTIFICATE CreditCardNumberCert
WITH SUBJECT = 'Protect creditcard'
GO

CREATE CERTIFICATE CostPriceCert
WITH SUBJECT = 'Protect costprice'
GO

-- create a symmetric key which can be encrypted using any of the certificate, password, and symmetric key, asymmetric key options
CREATE SYMMETRIC KEY PasswordKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE PasswordCert
GO

CREATE SYMMETRIC KEY CreditCardNumberKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CreditCardNumberCert
GO

CREATE SYMMETRIC KEY CostPriceKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CostPriceCert
GO


-- ******* Manual update of encrypted keys - in case if required ***********
-- encrypting Customer.Password, CreditCard.Credit_Card_Number, and Product.Cost_Price 
OPEN SYMMETRIC KEY PasswordKey
DECRYPTION BY CERTIFICATE PasswordCert;

UPDATE Customer SET Password = ENCRYPTBYKEY(KEY_GUID('PasswordKey'),Password);

CLOSE SYMMETRIC KEY PasswordKey;

OPEN SYMMETRIC KEY CreditCardNumberKey
DECRYPTION BY CERTIFICATE CreditCardNumberCert;

UPDATE CreditCard SET Credit_Card_Number = ENCRYPTBYKEY(KEY_GUID('CreditCardNumberKey'), Credit_Card_Number);

CLOSE SYMMETRIC KEY CreditCardNumberKey;

OPEN SYMMETRIC KEY CostPriceKey
DECRYPTION BY CERTIFICATE CostPriceCert;

UPDATE Product SET Cost_Price = ENCRYPTBYKEY(KEY_GUID('CostPriceKey'), CONVERT(VARCHAR(30), Cost_Price));

CLOSE SYMMETRIC KEY CostPriceKey;



