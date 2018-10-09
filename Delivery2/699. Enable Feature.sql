Use Portal_Data
Go

Select *
From SAP.Branch
Where SAPBranchID = '1138'

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1138, 1)

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Go

Use Merch
Go

Update Setup.Config
Set Value = '1120,1138'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go



