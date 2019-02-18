Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

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
