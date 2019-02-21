Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Insert Smart.Config
Values(2, 'Branch Inclusion', 'All', SYSDATETIME())

Insert Smart.Config
Values(3, 'National Chain Exclusion', 'None', SYSDATETIME())
Go
