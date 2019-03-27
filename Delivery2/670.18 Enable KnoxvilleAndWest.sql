Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName = 'Knoxville'

Select *
From SAP.Branch
Where SAPBranchID = '1164'
Go

Select BUName, RegionName, AreaName, SAPBranchID, BranchName
From SAP.Branch b 
Join SAP.Area a on b.AreaID = a.AreaID
Join SAP.Region r on a.regionID = r.RegionID
Join SAP.BusinessUnit bu on r.BUID = bu.BUID
Where SAPBranchID in (
	Select BranchID From Shared.Feature_Authorization Where FeatureID = 6
	)
	And SAPBranchID <> 'TJW1'
Order By BUName, RegionName, AreaName, SAPBranchID
Go

Delete
From Shared.Feature_Authorization
Where BranchID = 1060
And FeatureID = 6
Go

Alter Proc dbo.pEnableBranchesForMesh
As
	Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
	Select 6 FeatureID, SAPBranchID BranchID, 1 IsActive
	From SAP.Branch
	Where SAPBranchID in (
	1060 
	)
	And SAPBranchID <> 'TJW1'
	And SAPBranchID Not In (Select BranchID From Shared.Feature_Authorization Where FeatureID = 6)

	Delete From Shared.Feature_Authorization Where BranchID = -1 And FeatureID = 6

	Declare @V Varchar(8000)
	Set @V = '' 

	Select @V = @V + Convert(Varchar(10), BranchID) + ','
	From Shared.Feature_Authorization
	Where FeatureID = 6
	Order By BranchID

	Select SUBSTRING(@V, 1, Len(@V) - 1) ConfigValue

	Update Merch.Setup.Config
	Set Value = SUBSTRING(@V, 1, Len(@V) - 1)
	Where ConfigID = 4
Go

exec dbo.pEnableBranchesForMesh1
Go

--Select Count(*) Cnt 
--From Shared.Feature_Authorization
--Where FeatureID = 6

--Select *
--From Merch.Setup.Config
--Go

--Select *
--From Portal_Data.Shared.Feature_Authorization
--Where featureid = 6
--Order By BranchID
--Go

--Select *
--From Portal_Data.Shared.Features

