Use Merch
Go

If Exists (Select * From sys.procedures Where Name = 'pUpdateEstimatedArrivals')
Begin
	Drop Proc Mesh.pUpdateEstimatedArrivals
	Print '* Mesh.pUpdateEstimatedArrivals'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc Mesh.pUpdateEstimatedArrivals
(
	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(50),
	@LastModifiedUTC DateTime2(0)
)
As
	Set NoCount On;

	If (Select Count(*) From @Estimates) > 0
	Begin

		Declare @DateString varchar(20)
		Declare @IsStarted Bit
		Declare @DeliveryDateUTC Date
		Declare @RouteID Int
		Declare @TotalRouteAffected Table
		(
			DeliveryDateUTC Date,
			RouteID int
		)

		Insert Into @TotalRouteAffected 
		Select DeliveryDateUTC, RouteID
		From @Estimates e
		Join Mesh.DeliveryStop ds on e.DeliveryStopID = ds.DeliveryStopID
		Group By DeliveryDateUTC, RouteID
	
		If (Select Count(*) From @TotalRouteAffected) > 1
		Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

			RAISERROR (N'[ClientDataError]{Mesh.pUpdateEstimatedArrivals}: More than one Route/Date combination found in the updated estimates' , -- Message text.  
				16, -- Severity,  
				1 -- State
				);
		End

		Else If (Select Count(*) From @TotalRouteAffected) = 0
		Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

			RAISERROR (N'[ClientDataError]{Mesh.pUpdateEstimatedArrivals}: No Route/Date combination found in the updated estimates' , -- Message text.  
				16, -- Severity,  
				1 -- State
				);
		End

		Else 
		Begin
			Select @IsStarted = IsStarted, @DeliveryDateUTC = dr.DeliveryDateUTC, @RouteID = dr.RouteID
			From @Estimates e
			Join Mesh.DeliveryStop ds on e.DeliveryStopID = ds.DeliveryStopID
			Join Mesh.DeliveryRoute dr on ds.DeliveryDateUTC = dr.DeliveryDateUTC and ds.RouteID = dr.RouteID
			Group By dr.DeliveryDateUTC, dr.RouteID, IsStarted

			If @IsStarted = 0
			Begin
			Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

				RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: The route has not been checked out. @RouteID=%i and @DeliveryDateUTC=%s.' , -- Message text.  
					16, -- Severity,  
					1, -- State,  
					@RouteID, -- First argument.  
					@DateString); -- Second argument.  
			End
			Else 
			Begin
				Merge Mesh.DeliveryStop t
				Using (Select DeliveryStopID, Sequence, EstimatedArrivalTime
						From @Estimates
				) as S
				On t.DeliveryStopID = s.DeliveryStopID
				When Matched 
				Then Update Set t.Sequence = s.Sequence
								,t.EstimatedArrivalTime = s.EstimatedArrivalTime
								,EstimatedDepartureTime = DateAdd(second, IsNull(ServiceTime, 0), s.EstimatedArrivalTime)
								,t.LastModifiedBy = @LastModifiedBy
								,t.LastModifiedUTC = @LastModifiedUTC
								,t.LocalUpdateTime = SysDateTime();
			End
		End
	End
Go

Print 'Mesh.pUpdateEstimatedArrivals created'
Go

--

Declare @Estimates Mesh.tEstimatedArrivals
Declare @CurrentDate DateTime

--Insert Into @Estimates
--Values (2203, 1, '2018-06-14T17:09:37')

--Insert Into @Estimates
--Values (
--2204, 2, '2018-06-14T18:19:47')

--Insert Into @Estimates
--Values (
--2208, 3, '2018-06-14T19:16:28')

--Insert Into @Estimates
--Values (
--2206, 4, '2018-06-14T20:47:58')

--Insert Into @Estimates
--Values (
--2202, 5, '2018-06-14T21:29:50')

--Insert Into @Estimates
--Values (
--2207, 6, '2018-06-14T22:46:10')

--Insert Into @Estimates
--Values (
--2205, 7, '2018-06-15T00:01:13')

Set @CurrentDate = '2018-06-14T16:19:16'

exec Mesh.pUpdateEstimatedArrivals 
@Estimates, 'BRODX029', @CurrentDate

Select * From Mesh.DeliveryStop
Where DeliveryDateUTC = '2018-06-14'
And RouteID = 112002011
Order By Sequence

