-- Auditing.sql

/* ========================================================================================================================= */
/* tracking changes made to Product table along with user information and data before and after the change */
-- we use Change Data Capture to track all the table changes
-- first, we will make SQL server agent running and enable CDC on database

USE master;
GO

EXEC sp_cdc_enable_db;

-- configure CDC on Product table; capture all changes on all columns for table Product
EXEC sys.sp_cdc_enable_table @source_schema='dbo',
@source_name='Product',
@role_name='cdc_Product'
-- Member of role cdc_Product will have access to CDC


-- alter table change_tables and add column to store user details who make changes
SELECT * FROM cdc.change_tables
ALTER TABLE cdc.change_tables 
ADD UserName SYSNAME NOT NULL DEFAULT USER_SNAME(),
eventDate DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;


-- track the table changes using below query
-- returns a row for each change in the source table that belongs to the Log Sequence Number in the range 
-- specified by the input parameters (with before and after data)
DECLARE @from_lsn  binary(100), @to_lsn  binary(100);
SET @from_lsn = sys.fn_cdc_get_min_lsn('Product');
SET @to_lsn = sys.fn_cdc_get_max_lsn();
 
SELECT __$start_lsn
       , __$seqval
       , CASE
              WHEN __$operation = 1 THEN 'DELETE'
              WHEN __$operation = 2 THEN 'INSERT'
              WHEN __$operation = 3 THEN 'PRE-UPDATE'
              WHEN __$operation = 4 THEN 'POST-UPDATE'
              ELSE 'UNKNOWN'
       END AS Operation
       , __$update_mask,
	   UserName,
	   eventDate
FROM cdc.fn_cdc_get_all_changes_dbo_Product(@from_lsn, @to_lsn, N'all update old')
ORDER BY __$seqval


/**** Was not able to execute change data capture queries (above) due to limited permission **/
/**** create trigger to track changes made to product table *****/

CREATE TABLE ProductSecurityAudit
(
SessionID uniqueidentifier NOT NULL,  
Product_id VARCHAR(30) NOT NULL,
Name VARCHAR(30), 
Quantity INT, 
Description VARCHAR(100), 
Cost_Price VARBINARY(MAX), 
Sales_Price DECIMAL (5, 2),
Discount DECIMAL (4, 2),
Action NVARCHAR(10) NOT NULL CHECK (Action IN ('Deleted','Updated')),  
RowType NVARCHAR(10) NOT NULL CHECK (RowType IN ('New','Old','Deleted')), 
ChangedDate DATETIME NOT NULL DEFAULT GETDATE(),  
ChangedBy SYSNAME NOT NULL DEFAULT USER_NAME()
);


CREATE TRIGGER TR_Product_Audit 
ON Product 
FOR INSERT, UPDATE, DELETE
AS
BEGIN  
    SET NOCOUNT ON
    DECLARE @SessionID uniqueidentifier
    SET @SessionID = NEWID()

    INSERT ProductSecurityAudit(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount, Action, RowType, SessionID)
    SELECT Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount, 'Updated','Old', @SessionID FROM Deleted

    INSERT ProductSecurityAudit(Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount, Action, RowType, SessionID)
    SELECT Product_id, Name, Quantity, Description, Cost_Price, Sales_Price, Discount, 'Updated','New', @SessionID FROM Inserted
END

-- view tracked information about product table
SELECT * FROM ProductSecurityAudit;


/* ========================================================================================================================= */
/* track any permission change by GRANT/REVOKE/DENY statement */
USE master ;
GO

-- Create the server audit
CREATE SERVER AUDIT CompanyPermissionAudit
TO FILE 
( FILEPATH = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log'
	,MAXSIZE = 0 MB
    ,MAX_ROLLOVER_FILES = 2147483647
    ,RESERVE_DISK_SPACE = OFF 
)
WITH
( QUEUE_DELAY = 1000
  ,ON_FAILURE = CONTINUE
)
GO

-- enable the server audit
ALTER SERVER AUDIT CompanyPermissionAudit 
WITH (STATE = ON);
GO


-- create databased audit specification using predefined DB-level audit action group
CREATE DATABASE AUDIT SPECIFICATION PermissionAuditSpecification
FOR SERVER AUDIT CompanyPermissionAudit
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP) WITH (STATE = ON);
GO

-- enable database audit specification
ALTER DATABASE AUDIT SPECIFICATION PermissionAuditSpecification
WITH (STATE = ON);
GO

-- view Audit logs
SELECT TOP(1000) *
FROM sys.fn_get_audit_file (N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log\*.sqlaudit', null, null )
ORDER BY action_id
GO


/* ========================================================================================================================= */
/* retrieve all failed login attempts for a given user */
-- we use SQL server audit feature - Server-level Auditing
-- create server audit object

CREATE SERVER AUDIT FailedLoginAttempts
TO FILE
( FILEPATH = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log'
	,MAXSIZE = 0 MB
    ,MAX_ROLLOVER_FILES = 2147483647
    ,RESERVE_DISK_SPACE = OFF 
)
WITH
( QUEUE_DELAY = 1000
  ,ON_FAILURE = CONTINUE
)
GO

-- enable server audit
ALTER SERVER AUDIT FailedLoginAttempts
WITH (STATE = ON)
GO

-- create Server Audit Specification
CREATE SERVER AUDIT SPECIFICATION
FailedLoginAuditSpecification
FOR SERVER AUDIT FailedLoginAttempts
ADD (FAILED_LOGIN_GROUP);


-- enable the Server Audit Specification
ALTER SERVER AUDIT SPECIFICATION
FailedLoginAuditSpecification
WITH (STATE = ON)

-- retrieves audit specifications at sever instance
SELECT * FROM sys.server_audit_specifications

-- view Audit logs
SELECT TOP(1000) *
FROM sys.fn_get_audit_file(N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log\FailedLogin*.sqlaudit', null, null)
ORDER BY event_time DESC, sequence_number


/* ========================================================================================================================= */
/* retrieve all session information for a given user along with login and logout event */
-- we use SQL server audit feature - Server-level Auditing
-- create server audit object
CREATE SERVER AUDIT UserSessionInformation
TO FILE
( FILEPATH = N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log'
	,MAXSIZE = 0 MB
    ,MAX_ROLLOVER_FILES = 2147483647
    ,RESERVE_DISK_SPACE = OFF
)
WITH
( QUEUE_DELAY = 1000
  ,ON_FAILURE = CONTINUE
)
GO

-- enable server audit
ALTER SERVER AUDIT UserSessionInformation
WITH (STATE = ON)
GO

-- create Server Audit Specification
CREATE SERVER AUDIT SPECIFICATION
UserSessionAuditSpecification
FOR SERVER AUDIT UserSessionInformation
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (DATABASE_LOGOUT_GROUP);


-- enable the Server Audit Specification
ALTER SERVER AUDIT SPECIFICATION
UserSessionAuditSpecification
WITH (STATE = ON)


-- retrieves audit specifications at sever instance
SELECT * FROM sys.server_audit_specifications;

-- retrieves user session information such as login time and last successful logon
SELECT * FROM sys.dm_exec_sessions;
	

-- view session information of a user along with login and logout timestamp
-- LGIS: Login Succeeded action
-- LGIF: Login Failed action
-- LGO: Logout action
SELECT T1.event_time AS LoginTimestamp, T2.event_time AS LogoutTimestamp,
T1.session_server_principal_name AS UserName, T1.session_id
FROM sys.fn_get_audit_file(N' C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log\UserSession*.sqlaudit', null, null) T1,
sys.fn_get_audit_file(N' C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log\UserSession*.sqlaudit', null, null) T2
WHERE T1.action_id = 'LGIS' AND T1.session_id = T2.session_id -- AND T2.action_id = 'LGO' 


SELECT TOP(1000) *
FROM sys.fn_get_audit_file(N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQLEXPRESS01\MSSQL\Log\UserSession*.sqlaudit', null, null)
ORDER BY session_id DESC;










