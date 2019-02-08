Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select Cnt, Count(*) Cnt1
From Smart.Daily
Group By Cnt
Order By Cnt

Select DeliveryDate, Count(*) Cnt, DATENAME(dw, DeliveryDate) DayOfWeek
From Smart.SalesHistory 
Group By DeliveryDate
Order By DeliveryDate

Select *
From ETL.DataLoadingLog

Select Count(*)
From Smart.SalesHistory 

Select Top 100 *
From Smart.Daily

Select Distinct DeliveryDate
From Staging.RMDailySale


Select Count(*)
From Smart.Daily

Go

