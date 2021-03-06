/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [SESSION_DATE]
      ,[ROUTE_ID]
      ,[LOCATION_ID]
      ,[ORDER_NUMBER]
      ,[BAY_NUMBER]
      ,[SKU]
      ,[QUANTITY]
      ,[TOTAL_QUANTITY]
      ,[LAST_UPDATE]
  FROM [Portal_Data].[Apacheta].[FleetLoader]
  order by session_Date desc