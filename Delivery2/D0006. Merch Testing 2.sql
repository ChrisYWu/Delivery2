use Merch
Go

Select *
From APNSMerch.DeliveryInfo
Where DeliveryDateUTC = '2019-01-09'
And SAPAccountNumber in (12006048
,11321447
,11963702
,11326130
,11320992
,11323174)

Select top 10 *
From SEtup.WebAPILog
Order By LogiD desc

Select *
From APNSMerch.StoreDeliveryTimeTrace

Select *
From Mesh.DeliveryStop
Where DeliveryStopId = 66471

Select *
From APNSMerch.DeliveryInfo
Where SAPAccountNumber =11320992

Delete
From APNSMerch.StoreDeliveryTimeTrace

Update Mesh.DeliveryStop
SEt CheckInTime = null, ArrivalTime = null





Declare @Known Table
(
	DeliveryStopId int
)

Insert Into @Known(DeliveryStopId) Values (66471)
Insert Into @Known(DeliveryStopId) Values (66472)
Insert Into @Known(DeliveryStopId) Values (66474)
Insert Into @Known(DeliveryStopId) Values (66470)
Insert Into @Known(DeliveryStopId) Values (66477)
Insert Into @Known(DeliveryStopId) Values (66473)
Insert Into @Known(DeliveryStopId) Values (66475)

	Declare @DeliveryInfo Table
	(
		DeliveryDateUTC date NOT NULL,
		SAPAccountNumber int NOT NULL,
		ArrivalTime datetime2(0) NULL,
		IsEstimated bit NOT NULL,
		DNS bit NULL,
		LastModifiedBy varchar(50) NOT NULL
	)

	-- The stop type other than STP will be filtred out by the field SAPAccountNumber
	Insert Into @DeliveryInfo
	Select ds.DeliveryDateUTC, 
		ds.SAPAccountNumber, 
		Coalesce(ds.ArrivalTime, ds.EstimatedArrivalTime, ds.PlannedArrival) ArrivalTime, 		
		Case When ds.ArrivalTime Is Null Then 1 Else 0 End IsEstimated,
		ds.DNS, 
		ds.LastModifiedBy
	From Mesh.DeliveryStop ds
	Where DeliveryStopID in (Select DeliveryStopID From @Known)
	And StopType = 'STP'
	And SAPAccountNumber is not null

	Select * From @DeliveryInfo

	Update Mesh.DeliveryStop
	Set CheckInTime = null, ArrivalTime = null


	Select 
	sm.*, TimeZoneOffSet, 
	p.GSN,
	'[' + b.BranchName + ']' + 
	Case 
		When sm.DNS = 1 Then 'Delivery for ' 
		When sm.IsEstimated = 1 Then 'The new estimated delivery arrival for ' 
		Else 'Delivery for ' End 
	+
	Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
	+
	Case When sm.DNS = 1 Then 'is canceled'  
		When sm.IsEstimated = 1 Then 'is ' 
		Else 'is arrived at ' End 
	+
	Case When sm.DNS = 1 Then '' 
		Else Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, sm.ArrivalTime), 100), 13, 100) End Message
	From 
	@DeliveryInfo ds
	Join APNSMerch.DeliveryInfo sm on sm.SAPAccountNumber = ds.SAPAccountNumber And ds.DeliveryDateUTC = sm.DeliveryDateUTC
	Join Setup.Merchandiser p on sm.MerchandiserGSN = p.GSN
	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	Join SAP.Branch b on a.BranchID = b.BranchID
	And (( Delta > 1800 ) Or ( Delta <> 0 And sm.IsEstimated = 0))

Insert [Setup].[Merchandiser]
([GSN]
      ,[MerchGroupID]
      ,[DefaultRouteID]
      ,[PictureURL]
      ,[Phone]
      ,[Mon]
      ,[Tues]
      ,[Wed]
      ,[Thu]
      ,[Fri]
      ,[Sat]
      ,[Sun]
      ,[LastModified]
      ,[LastModifiedBy])
Select * From DPSGSHAREDCLSTR.Merch.[Setup].[Merchandiser]
Where GSN Not in (Select GSN From SEtup.Merchandiser)


Insert SEtup.Person
( [GSN]
      ,[FirstName]
      ,[LastName]
      ,[MiddleName]
      ,[Picture]
      ,[Email]
      ,[Phone]
      ,[iPhoneNotificationToken]
      ,[LastModified]
      ,[LastModifiedBy]
)
Select * 
  FROM DPSGSHAREDCLSTR.Merch.[Setup].[Person]
Where GSN Not in (Select GSN From SEtup.Person)
GO

