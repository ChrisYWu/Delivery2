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

-------------------------------------------------------------------------------------------------
USE [Merch]
GO
/****** Object:  StoredProcedure [Export].[pGetStoreServiceReport]    Script Date: 9/14/2018 1:29:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

EXEC Export.pGetStoreServiceReport '5,7', '2017-12-12', '2017-12-12'
EXEC Export.pGetStoreServiceReport '184', '2017-12-2', '2017-12-22'

*/

ALTER Proc [Export].[pGetStoreServiceReport]
(
	@MerchGroupIDs VARCHAR(4000),
	@FromDate Date,
	@ToDate Date
)
AS

BEGIN

	Select  branch.BranchName as Branch,
		ltrim(p.FirstName) + ' ' + ltrim(p.LastName) as Merchandiser,
		convert(varchar, chkOut.ClientCheckOutTime, 101) as 'Date',
		chain.LocalChainName as 'Chain',
		acc.AccountName as 'StoreName', 
		convert(nvarchar, CAST(chkIn.ClientCheckInTime as time), 100)  + ' ' + chkIn.ClientCheckInTimeZone as 'StartTime',	
		convert(nvarchar, CAST(chkOut.ClientCheckOutTime as time), 100)  + ' ' + chkOut.ClientCheckOutTimeZone as 'EndTime',
		chkIn.ClientCheckInTime,
		chkOut.ClientCheckOutTime,	 
		convert(varchar(10),DateDiff(minute, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime) ) as 'TimeinStoreMins',
		convert(varchar(5),DateDiff(s, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime)/3600)+' hrs '+convert(varchar(5),DateDiff(s, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime)%3600/60) + ' mins' as 'TimeinStoreHours',
		REPLACE(ltrim(sig.ManagerName), ',',' ') as 'ManagerName', 		
		CAST(sig.ImageBlobID as VARCHAR(50)) as 'ManagerSignature',		
		chkOut.CasesHandeled as 'CasesWorked', 
		chkOut.CasesInBackroom as 'CasesInBackstock',		
		STUFF((
				Select ';' + CAST(pic.PictureBlobID as VARCHAR(50)) from Operation.MerchStorePicture pic 
				where pic.DispatchDate = chkIn.DispatchDate and pic.GSN = chkIn.GSN and pic.SAPAccountNumber = chkIn.SAPAccountNumber and pic.DispatchDate = chkIn.DispatchDate
			FOR XML PATH('')
					,TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as 'StorePics',
		

		STUFF((
				Select '; ' + pic.Caption from Operation.MerchStorePicture pic 
				where pic.DispatchDate = chkIn.DispatchDate and pic.GSN = chkIn.GSN and pic.SAPAccountNumber = chkIn.SAPAccountNumber and pic.DispatchDate = chkIn.DispatchDate
			FOR XML PATH('')
					,TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as 'PicsLocation',
		Replace(Replace(Replace(chkOut.Comments, ',', ';'), Char(10), ''), Char(13), '') Comments,
		dbo.udfDistanceInMiles(acc.Latitude, acc.Longitude, chkIn.CheckInLatitude, chkIn.CheckInLongitude) CKINDistance,
		dbo.udfDistanceInMiles(acc.Latitude, acc.Longitude, chkOut.CheckOutLatitude, chkOut.CheckOutLongitude) CKOUTDistance,
		'"' + convert(varchar(40),acc.Latitude)  + ',' + convert(varchar(40),acc.Longitude) + '"' as 'StoreLocation',
		'"' + convert(varchar(40),chkIn.CheckInLatitude)  + ',' + convert(varchar(40),chkIn.CheckInLongitude) + '"' as 'CKINLocation',
		'"' + convert(varchar(40),chkOut.CheckOutLatitude)  + ',' + convert(varchar(40),chkOut.CheckOutLongitude) + '"' as 'CKOUTLocation',
		acc.Address, acc.City,acc.PostalCode, acc.State
	from Operation.MerchStopCheckIn chkIn 
	left Join Operation.MerchStopCheckOut chkOut  on chkIn.MerchStopID = chkOut.MerchStopID
	left Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
	left join SAP.LocalChain chain on acc.LocalChainID = chain.LocalChainID
	left join Operation.MerchStoreSignature sig on chkIn.GSN = sig.GSN  and sig.SAPAccountNumber = chkIn.SAPAccountNumber and sig.DispatchDate = chkIn.DispatchDate
	left join Setup.MerchGroup grp on chkIn.MerchGroupID = grp.MerchGroupID
	inner join SAP.Branch branch on branch.SAPBranchID = grp.SAPBranchID
	left join Setup.Person p on p.GSN = chkIn.GSN
	Where chkIn.MerchGroupID in (Select value  From Setup.UDFSplit(@MerchGroupIDs, ','))
		AND chkIn.DispatchDate between @FromDate and @ToDate
		
END
Go

Print 'Export.pGetStoreServiceReport updated at ' + convert(varchar(200), GetDate())
Go
