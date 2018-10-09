USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pGetDeliveryManifest')
Begin
	Drop Proc Mesh.pGetDeliveryManifest
	Print '* Mesh.pGetDeliveryManifest'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec Mesh.pGetDeliveryManifest @DeliveryDateUTC = '2018-02-15', @RouteID = 110901504
exec Mesh.pGetDeliveryManifest @RouteID = 110901006
exec Mesh.pGetDeliveryManifest @RouteID = 111501301

		Select *
		From Mesh.DeliveryRoute
		Where DeliveryDateUTC = '2018-04-16'
		And RouteID = 111501301

*/

--Select *
--From Mesh.PlannedStop
--Where RouteID in (
--Select Distinct RouteID
--From Mesh.PlannedStop
--Where DeliveryDATEUTC = '2018-06-05'
--And TravelTotime = 0
--And SEquence > 0
--And StopType = 'STP'
--)
--And DeliveryDATEUTC = '2018-06-05'


--SElect *
--From Mesh.PlannedStop
--Where DeliveryDATEUTC = '2018-06-05'
--And SAPAccountNumber in (
--Select SAPAccountNumber
--From Mesh.PlannedStop
--Where DeliveryDATEUTC = '2018-06-05'
--And StopType = 'STP'
--Group By RouteID, SAPAccountNumber
--having Count(*) > 1
--)
--And TravelToTime = 0

Create Proc Mesh.pGetDeliveryManifest
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

			Select @SAPAccountNumber = SAPAccountNumber, @TravelToTime = TravelToTime, @ServiceTime = ServiceTime From @Conso Where Sequence = @Cur
			--Select @Cur Cur, @SAPAccountNumber SAPAccountNumber, @TravelToTime TravelToTime
			
			If ((@LastSAPAccountNumber = @SAPAccountNumber) And (@TravelToTime = 0))
			Begin
				--Select SAPAccountNumber, Sequence From @Conso
				Update @Conso Set ServiceTime = ServiceTime + @ServiceTime Where Sequence = @LastHitCur
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

		--Select * From @Conso

		----------------------------------------------------------
		--ENDofCONSOLIDATE----ENDofCONSOLIDATE--ENDofCONSOLIDATE--

		If (@IsStarted = 0)
		Begin
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

Print 'Mesh.pGetDeliveryManifest created'
Go

--
exec Mesh.pGetDeliveryManifest @RouteID = 108000513
Go

Select *
From Mesh.PlannedStop
Where DeliveryDATEUTC = '2018-06-05'
And RouteID = 108000513
Go



