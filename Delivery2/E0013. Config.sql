Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

--Insert Smart.Config
--Values(2, 'Branch Inclusion', 'All', SYSDATETIME())

Insert Smart.Config
Values(3, 'National Chain Exclusion', 'None', SYSDATETIME())
Go

Insert Smart.Config
Values(4, 'Weekend Split', '0.5', SYSDATETIME())
Go

Select * From Smart.Config


Select 0.2143 * 7
Select 0.214 * 7
Select 0.21 * 7
