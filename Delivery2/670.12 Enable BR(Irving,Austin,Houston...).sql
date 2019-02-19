Use Merch
Go

Select @@SERVERNAME Server
Go

Select DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName like 'HOUSTON%'

-------------------------------------------
Use Portal_Data
Go

Select *
From SAP.Branch Where SAPBranchID = '1116'
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1108, 1)
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1109, 1)
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1113, 1)
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1114, 1)
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1115, 1)
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1117, 1)
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Order By BranchID
Go

Use Merch
Go

Update Setup.Config
Set Value = '1103,1104,1108,1109,1113,1114,1115,1116,1117,1120,1138,1178'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go

Print '-- $$$$ Branch enabled [BR - 20190218] $$$$--'
Go

