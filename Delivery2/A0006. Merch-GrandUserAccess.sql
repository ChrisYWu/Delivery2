use Merch
Go

Select *
From Setup.UserLocation
Where GSN = 'GUPPX008'
Go

Insert Setup.UserLocation(GSN, SAPBranchID, LastModified, LastModifiedBy)
Select Distinct 'GUPPX008' GSN, SAPBranchID, GetDAte(), 'WUXYX001' LastModifiedBy
From Setup.UserLocation
Where GSN != 'GUPPX008'
Order By SAPBranchID
Go
