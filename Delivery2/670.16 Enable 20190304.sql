Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName = 'San Diego'

Select *
From SAP.Branch
Where SAPBranchID = '1031'
Go

Alter Proc dbo.pEnableBranchesForMesh1
As
	Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
	Select 6 FeatureID, SAPBranchID BranchID, 1 IsActive
	From SAP.Branch
	Where SAPBranchID in (
	1131
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

Select Count(*) Cnt 
From Shared.Feature_Authorization
Where FeatureID = 6

Select *
From Merch.Setup.Config
Go

Select *
From Portal_Data.Shared.Feature_Authorization
Where featureid = 6
Order By BranchID
Go

Select *
From Portal_Data.Shared.Features

