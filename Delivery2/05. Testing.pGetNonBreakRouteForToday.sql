use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('Testing.pGetNonBreakRouteForToday'))
Begin
	Drop Proc Testing.pGetNonBreakRouteForToday
	Print '* Testing.pGetNonBreakRouteForToday'
End
Go

/*
TESTING QUERY

exec Testing.pGetNonBreakRouteForToday
exec Testing.pGetNonBreakRouteForToday 1

*/

Create Proc Testing.pGetNonBreakRouteForToday
(
	@Inverse bit = 0
)
As
	Set NOCOUNT ON;
	
	Select Distinct b.RMLocationID, b.BranchName, RouteNumber, RouteName
	From Operation.Delivery d
	Join Portal_Data.SAP.Route r On d.RouteNumber = r.SAPRouteNumber
	Join Portal_Data.SAP.Branch b on r.BranchID = b.BranchID
	Where 
	(
		(
			@Inverse = 0
			And
			RouteNumber not in
			(
				Select Distinct RouteNumber
				From Operation.Delivery
				Where StopType = '4:Break'
			)
		)
		Or
		(
			@Inverse = 1
			And
			RouteNumber in
			(
				Select Distinct RouteNumber
				From Operation.Delivery
				Where StopType = '4:Break'
			)
		)
	)
	And DeliveryDate = '2017-04-04'
	Order By b.BranchName, RouteName, RouteNumber

Go

--exec Testing.pGetNonBreakRouteForToday

Print 'Creating Testing.pGetNonBreakRouteForToday'
Go


