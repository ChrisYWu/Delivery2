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

Insert Into Staging.RMDailySale 
Select * From OpenQuery(RM, 
'SELECT IV.DELIVERY_DATE DELIVERY_DATE, IV.CUSTOMER_NUMBER ACCOUNT_NUMBER, ID.ITEM_NUMBER, SUM(ID.CASEQTY) DELIVERYCASEQTY 
FROM ACEUSER.INVOICE_MASTER IV, ACEUSER.INVOICE_DETAIL ID, ACEUSER.ITEM_MASTER IM  WHERE TO_CHAR(IV.DELIVERY_DATE, ''YYYY-MM-DD'') > ''2019-02-10'' AND TO_CHAR(IV.DELIVERY_DATE, ''YYYY-MM-DD'') <  ''2019-02-14'' AND IV.ORDER_STATUS IN (6,7) AND IV.INVOICE_NUMBER = ID.INVOICE_NUMBER AND IV.TYPE = ''D'' AND ID.CASEQTY > 0 AND ID.ITEM_NUMBER = IM.ITEM_NUMBER AND IV.LOCATION_ID = IM.LOCATION_ID AND IM.MATERIAL_TYPE IN (''FERT'', ''HAWA'') GROUP BY IV.LOCATION_ID, IV.CUSTOMER_NUMBER, IV.DELIVERY_DATE, ID.ITEM_NUMBER ')