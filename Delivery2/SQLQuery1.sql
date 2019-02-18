/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [DeliveryStopID]
      ,[PlannedStopID]
      ,[DeliveryDateUTC]
      ,[RouteID]
      ,[Sequence]
      ,[StopType]
      ,[SAPAccountNumber]
      ,[IsAddedByDriver]
      ,[Quantity]
      ,[PlannedArrival]
      ,[ServiceTime]
      ,[TravelToTime]
      ,[Voided]
      ,[DNS]
      ,[DNSReasonCode]
      ,[DNSReason]
      ,[EstimatedArrivalTime]
      ,[CheckInTime]
      ,[ArrivalTime]
      ,[CheckInFarAwayReasonID]
      ,[CheckInDistance]
      ,[CheckInLatitude]
      ,[CheckInLongitude]
      ,[EstimatedDepartureTime]
      ,[CheckOutTime]
      ,[DepartureTime]
      ,[CheckOutLatitude]
      ,[CheckOutLongitude]
      ,[ActualServiceTime]
      ,[LastModifiedBy]
      ,[LastModifiedUTC]
      ,[LocalUpdateTime]
  FROM [Merch].[Mesh].[DeliveryStop]
  Where SAPAccountNumber = 11997248
  And DeliveryDateUTC = '2019-02-12'