Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Use merch
Go

Select DAtepart(year, LastModified) Year, Datepart(month, lastmodified) Month, count(*) Count
From [Operation].[AzureBlobStorage]
Group by DAtepart(year, LastModified), Datepart(month, lastmodified)
Order By DAtepart(year, LastModified), Datepart(month, lastmodified)

Select DeliveryDate, Count(*) Cnt, DATENAME(dw, DeliveryDate) DayOfWeek
From Smart.SalesHistory 
Group By DeliveryDate
Order By DeliveryDate

Select *
From Smart.DeliveryDateRange

Select Count(*)
From Smart.DeliveryDateRange
Where InRange = 1

Select *
From ETL.DataLoadingLog

Select *
From BSCCAP108.Portal_Data.ETL.DataLoadingLog

Select Count(*)
From Smart.SalesHistory 

Select Top 100 DeliveryDate, SAPAccountNumber Customer, SAPMaterialID SKU, Quantity
From Smart.SalesHistory 
Where Substring(convert(varchar(20), SAPAccountNumber), 1,1) <> '5'
Order by DeliveryDate Desc


Select top 100 SAPAccountNumber Customer, SAPMaterialID SKU, Sum1 Sum, Cnt [Number of Orders]
From Smart.Daily
Where Substring(convert(varchar(20), SAPAccountNumber), 1,1) <> '5'

---------------------------------------------
Declare @Total Float
Select @Total = Count(*)
From Smart.Daily
Select @Total

Select Cnt [Number of Orders], Count(*) Count, @Total Total, Count(*)/@Total * 100.0 '%'
From Smart.Daily
Group By Cnt
Order By Cnt
---------------------------------------------

Declare @test Smart.tCustomerOrderInput

Insert @test Values(11307896, '2019-02-11', '2019-03-03')
Insert @test Values(11307893, '2019-02-11', '2019-02-14')

exec Smart.pGetSuggestedOrdersForCustomers @SAPAccounts = @test
Go

Select Top 1 * From Smart.Daily1
Select Top 1 * From Smart.Daily

Select Substring(convert(varchar(20), SAPAccountNumber), 1,1), count(*) 
From Smart.Daily
Group By Substring(convert(varchar(20), SAPAccountNumber), 1,1)
Order By Substring(convert(varchar(20), SAPAccountNumber), 1,1)

