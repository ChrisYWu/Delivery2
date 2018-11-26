use Merch
Go

Select *
From Person.UserProfile
Where FirstName = 'Bernard'

ALPBD001

--Delete From Setup.UserLocation
--Where UserLocationID in (
--	Select Min(UserLocationID) UserLocationID 
--	From Setup.UserLocation
--	Where GSN = 'ALPBD001'
--	Group By SAPBranchID
--	Having Count(*) = 2
--)


Insert Setup.UserLocation(GSN, SAPBranchID, LastModified, LastModifiedBy)
Select Distinct 'ALPBD001' GSN, SAPBranchID, GetDAte(), 'WUXYX001' LastModifiedBy
From Setup.UserLocation
Where SAPBranchID Not In (Select Distinct SAPBranchID From Setup.UserLocation Where GSN = 'ALPBD001')
Order By SAPBranchID
Go


