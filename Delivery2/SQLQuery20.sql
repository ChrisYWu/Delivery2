/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [ZoneID]
      ,[BCNodeID]
      ,[ZoneName]
      ,[SystemID]
      ,[Active]
      ,[LastModified]
  FROM [Portal_Data].[BC].[Zone]
  where SystemId = 14