Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Set NoCount On
Go

exec ETL.pLoadRMDailySale


Select ErrorMessage
From ETL.DataLoadingLog

