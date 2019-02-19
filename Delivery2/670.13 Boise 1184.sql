Use Merch
Go

Select @@SERVERNAME Server
Go

Select DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName like 'Boise%'

-------------------------------------------
Use Portal_Data
Go

Select *
From SAP.Branch Where SAPBranchID = '1184'
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1184, 1)
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Order By BranchID
Go

Use Merch
Go

Update Setup.Config
Set Value = '1103,1104,1108,1109,1113,1114,1115,1116,1117,1120,1138,1178,1184'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go

Print '-- $$$$ Branch enabled [Boise 1184] $$$$--'
Go

