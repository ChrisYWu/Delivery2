USE [Merch]
GO
/****** Object:  StoredProcedure [Export].[pGetStoreServiceReport]    Script Date: 9/5/2018 2:33:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

If Exists (
	Select *
	From sys.sql_modules m
	Join sys.objects o on m.object_id = o.object_id
	Where name = 'udfDistanceInMiles')
Begin
	Drop Function dbo.udfDistanceInMiles
	Print '* dbo.udfDistanceInMiles'
End
Go

/*
Select Top 1 CheckInLatitude, CheckInLongitude, CheckoutLatitude, CheckoutLongitude, dbo.udfDistanceInMiles(Null,CheckinLongitude,Checkoutlatitude, CheckoutLongitude), *
From Operation.MerchStopCheckIn i
Join Operation.MerchStopCheckOut o on i.MerchStopID = o.MerchStopID
Where CheckInLatitude <> 0 
Order By i.MerchStopID Desc
Go

*/
Create Function dbo.udfDistanceInMiles
(
	@LatAnchor decimal(10,6) = null, 
	@LongAnchor decimal(10,6) = null, 
	@LatTarget decimal(10,6) = null, 
	@LongTarget decimal(10,6) = null
)
Returns Decimal(10,1)
As
Begin
	Declare @Result Decimal(10,1) = null
	
	If ((@LatAnchor is not null) And (@LongAnchor is not null) And (@LatTarget is not null) And (@LongTarget is not null))
	Begin
		Declare @Anchor geography = geography::Point(@LatAnchor, @LongAnchor, 4326);
		Declare @Target geography = geography::Point(@LatTarget, @LongTarget, 4326);

		Select @Result = @Anchor.STDistance(@Target)*0.000621371 -- Meter converted to miles
	End

	Return @Result

End
Go

Print 'Creating user function dbo.udfDistanceInMiles'
Go