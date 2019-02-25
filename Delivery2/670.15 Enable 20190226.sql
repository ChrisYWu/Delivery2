Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName like 'Reno' 
--1183,1185,1139
Go

Alter Proc dbo.pEnableBranchesForMesh
As
	Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
	Select 6 FeatureID, SAPBranchID BranchID, 1 IsActive
	From SAP.Branch
	Where SAPBranchID in (
	1183,1185,1139
	)
	And SAPBranchID <> 'TJW1'
	And SAPBranchID Not In (Select BranchID From Shared.Feature_Authorization Where FeatureID = 6)

	Declare @V Varchar(8000)
	Set @V = '' 

	Select @V = @V + Convert(Varchar(10), BranchID) + ','
	From Shared.Feature_Authorization
	Where FeatureID = 6
	Order By BranchID

	Select SUBSTRING(@V, 1, Len(@V) - 1) ConfigValue
	-- 1103,1104,1108,1109,1113,1114,1115,1116,1117,1120,1138,1178,1184 Before changes
	-- 1103,1104,1108,1109,1113,1114,1115,1116,1117,1120,1138,1178,1184 SetupValue

	Update Merch.Setup.Config
	Set Value = SUBSTRING(@V, 1, Len(@V) - 1)
	Where ConfigID = 4
Go

exec dbo.pEnableBranchesForMesh
Go

Select Count(*) Cnt 
From Shared.Feature_Authorization
Where FeatureID = 6

Select *
From Merch.Setup.Config
Go

Select *
From Portal_Data.Shared.Feature_Authorization
Where featureid = 6
Go