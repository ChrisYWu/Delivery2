USE Merch
GO

Alter Proc Mesh.pGetDeliveryManifest
(
	@RouteID int,
	@DeliveryDateUTC date = null
)
As
    Set NoCount On;

	Declare @DateString varchar(20)
	Declare @Value varchar(max)
	Declare @MeshEnabled bit
	Set @MeshEnabled = 0

	Select @Value = Value
	From Setup.Config
	Where [Key] = 'MeshEnabledBranches'

	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())

	If Exists (	Select *
		From dbo.udfSplit(@Value, ',') branches
		Join SAP.Branch b on branches.Value = b.SAPBranchId
		Join SAP.Route r on r.BranchID = b.BranchID
		And r.SAPRouteNumber = @RouteID)
	Begin 
		Set @MeshEnabled = 1
	End

	If @MeshEnabled = 1
	Begin
		Select Convert(varchar(10), DeliveryDateUTC) DeliveryDateUTC, 
			RouteID, @MeshEnabled MeshEnabled, TotalQuantity, PlannedStartTime, FirstName, LastName, PhoneNumber, PlannedCompleteTime, PlannedServicetime, PlannedTravelTime, PlannedBreakTime, PlannedPreRoutetime, PlannedPostRoutetime
		From Mesh.DeliveryRoute dr
		Where DeliveryDateUTC = @DeliveryDateUTC
		And RouteID = @RouteID

		Declare @IsStarted bit

		Select @IsStarted = IsStarted
		From Mesh.DeliveryRoute
		Where DeliveryDateUTC = @DeliveryDateUTC
		And RouteID = @RouteID

		If (@IsStarted = 0)
		Begin
			--------------------------------------------------------
			--CONSOLIDATE----CONSOLIDATE--CONSOLIDATE--CONSOLIDATE--
			Declare @Conso Table
			(
				PlannedStopID int
				,DeliveryDateUTC Date
				,RouteID int
				,Sequence int
				,StopType varchar(20)
				,SAPAccountNumber varchar(50)
				,Quantity int
				,PlannedArrival datetime2(0)
				,ServiceTime int
				,TravelToTime int
				,LastModifiedBy varchar(50)
				,LastModifiedUTC datetime2(0)
				,LocalUpdateTime datetime2(0)
			)

			Insert Into @Conso
			Select PlannedStopID
				,DeliveryDateUTC
				,RouteID
				,Sequence + 1 Sequence
				,StopType
				,SAPAccountNumber
				,Quantity
				,PlannedArrival
				,ServiceTime
				,TravelToTime
				,'Dispatcher' LastModifiedBy
				,LastModifiedUTC
				,GetDate() LocalUpdateTime
			From Mesh.PlannedStop
			Where DeliveryDateUTC = @DeliveryDateUTC And RouteID = @RouteID

			Declare @LastSAPAccountNumber varchar(50)
			Declare @SAPAccountNumber varchar(50)
			Declare @StopType varchar(50)
			Declare @TravelToTime int
			Declare @ServiceTime int
			Declare @Cur int
			Declare @LastHitCur int
			Declare @MaxCur int
			Declare @Seq int
			Set @Cur = 0
			Select @MaxCur = Max(Sequence) From @Conso
			Select @LastSAPAccountNumber = @SAPAccountNumber From @Conso Where Sequence = @Cur
		
			While @Cur < @MaxCur
			Begin
				Set @Cur = @Cur + 1
				Select @LastHitCur	= Max(Sequence) From @Conso Where Sequence < @Cur

				Select	@SAPAccountNumber = SAPAccountNumber, 
						@TravelToTime = TravelToTime, 
						@ServiceTime = ServiceTime,
						@StopType = StopType 
				From @Conso Where Sequence = @Cur
			
				If (@StopType Not In ('STP', 'B', 'PB'))
				Begin
					Update @Conso Set TravelToTime = TravelToTime + @ServiceTime + @TravelToTime 
					Where Sequence = @Cur + 1
					
					Delete @Conso Where Sequence = @Cur				
				End

				If (@StopType = 'PB')
				Begin
					Update @Conso Set StopType= 'B' Where Sequence = @Cur
				End

				If (@LastSAPAccountNumber = @SAPAccountNumber) 
				Begin
					--Select SAPAccountNumber, Sequence From @Conso
					Update @Conso 
					Set ServiceTime = ServiceTime + @ServiceTime, 
						TravelToTime = TravelToTime + @TravelToTime
					Where Sequence = @LastHitCur
					
					Delete @Conso Where Sequence = @Cur
				End
				Select @LastSAPAccountNumber = @SAPAccountNumber

			End

			-- Need to adjust sequence ---
			Update c
			Set c.Sequence = t.RNum
			From @Conso c
			Join 
			(
			Select Row_Number() Over (Order By Sequence) As RNum, PlannedStopID
			From @Conso) t
			on c.PlannedStopID = t.PlannedStopID

			----------------------------------------------------------
			--ENDofCONSOLIDATE----ENDofCONSOLIDATE--ENDofCONSOLIDATE--

			Merge Mesh.DeliveryStop As t
			Using @Conso as S
			On t.DeliveryDateUTC = s.DeliveryDateUTC And t.RouteID = s.RouteID And t.PlannedStopID = s.PlannedStopID
			When Matched 
				Then Update Set t.Sequence = s.Sequence
								,t.StopType = s.StopType
								,t.SAPAccountNumber = s.SAPAccountNumber
								,t.Quantity = s.Quantity
								,t.PlannedArrival = s.PlannedArrival
								,t.ServiceTime = s.ServiceTime
								,t.TravelToTime = s.TravelToTime
								,t.LastModifiedBy = s.LastModifiedBy
								,t.LastModifiedUTC = s.LastModifiedUTC
								,t.LocalUpdateTime = s.LocalUpdateTime
			When Not Matched By Source And t.DeliveryDateUTC = @DeliveryDateUTC And t.RouteID = @RouteID
				Then Delete
			When Not Matched By Target
				Then Insert (PlannedStopID
			   ,DeliveryDateUTC
			   ,RouteID
			   ,Sequence
			   ,StopType
			   ,SAPAccountNumber
			   ,Quantity
			   ,PlannedArrival
			   ,ServiceTime
			   ,TravelToTime
			   ,LastModifiedBy
			   ,LastModifiedUTC
			   ,LocalUpdateTime)
			   Values
				(s.PlannedStopID
			   ,s.DeliveryDateUTC
			   ,s.RouteID
			   ,s.Sequence
			   ,s.StopType
			   ,s.SAPAccountNumber
			   ,s.Quantity
			   ,s.PlannedArrival
			   ,s.ServiceTime
			   ,s.TravelToTime
			   ,s.LastModifiedBy
			   ,s.LastModifiedUTC
			   ,s.LocalUpdateTime);

			Update Mesh.DeliveryRoute
			Set LastManifestFetched = SysDateTime()
			Where RouteID = @RouteID and DeliveryDateUTC = @DeliveryDateUTC;
			
			--- Output ---
			Select DeliveryStopID
					,convert(varchar(10), DeliveryDateUTC) DeliveryDateUTC
					,RouteID
					,Sequence
					,ds.StopType, d.Description StopDescription
					,ds.SAPAccountNumber
					,Quantity
					,PlannedArrival
					,ServiceTime
					,TravelToTime
					,Latitude
					,Longitude
			From Mesh.DeliveryStop ds
			Join Mesh.StopTypeDesc d on ds.StopType = d.StopType 
			Left Join SAP.Account a with (nolock) on ds.SAPAccountNumber = a.SAPAccountNumber
			Where DeliveryDateUTC = @DeliveryDateUTC And RouteID = @RouteID
			Order By Sequence
		End
		Else
		Begin
			If (@IsStarted is null)
			Begin
				Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

				RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: No Manifest found for @RouteID=%i and @DeliveryDateUTC=%s.' , -- Message text.  
				   16, -- Severity,  
				   1, -- State,  
				   @RouteID, -- First argument.  
				   @DateString); -- Second argument.  
			End
			Else
			Begin
				Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

				RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: Manifest is not available for @RouteID=%i and @DeliveryDateUTC=%s, The Route has been checked out for the day and delivery plan has been updated from Checkout Driver.' , -- Message text.  
				   16, -- Severity,  
				   1, -- State,  
				   @RouteID, -- First argument.  
				   @DateString); -- Second argument.  
			End
		End

	End
	Else 
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

		RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: Meshnet solution is not enabled at branch for @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
	End

GO

Print 'Mesh.pGetDeliveryManifest updated'
Go

--1. Find some routes from today's schedule that has special stops with types other than STP, B and PB
Use Merch
Go

Select @@SERVERNAME ServerName
Go

Declare @RouteIDInput int
Declare @DeliveryDateUTC Date
Set @DeliveryDateUTC = Convert(Date, GetDate())
Set @DeliveryDateUTC = DateAdd(Day, 1, @DeliveryDateUTC)

Select @DeliveryDateUTC DeliveryDateUTC

Select RouteID, Count(*)
From
(Select RouteID, StopType
From Mesh.PlannedStop
Where DeliveryDateUTC = @DeliveryDateUTC 
And StopType Not In ('STP', 'B', 'PW', 'PB', 'W')
) t
Group By RouteID
Order By RouteID

/*
Select Distinct RouteID
From Mesh.PlannedStop
Where DeliveryDateUTC = @DeliveryDateUTC 
And StopType Not In ('STP', 'B', 'PB')
Order By RouteID
*/

--2. Pick a RouteID
Set @RouteIDInput = 112002021

--3. Make sure the branch is enabled on the server side
/*
Select *
From Setup.Config
Where [Key] = 'MeshEnabledBranches'
*/

--3.1 If the branch is not enabled, either enable it with the code below, or go back and pick another one
/*
Update Setup.Config
Set Value = '1002,1010,1020,1034,1062,1090,1094,1120,1138,1178' -- Make sure it looks sorted
Where ConfigID = 4
*/

--3.2 If you want to verify it from Driver MyDay, enable the cliend side feature as well
/*
Use Portal_Data
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Order By BranchID

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1010, 1)
Go
*/

--
--Use Merch

exec Mesh.pGetDeliveryManifest @RouteID = 112002021

Select *
From Mesh.DeliveryRoute
Where RouteID =112002021
And DeliveryDateUTC = '10-30-2018'


Select *
From Mesh.PlannedStop
Where DeliveryDAteUTC = '2018-10-30'
And RouteID = 112002021
Order By Sequence
Go






