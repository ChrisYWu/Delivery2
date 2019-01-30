Use Merch
Go

Select @@SERVERNAME Server
Go

Select DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName like 'San Ant%'

-------------------------------------------
Use Portal_Data
Go

Select *
From SAP.Branch Where BranchName = 'Albuquerque'
And SAPBranchID = '1116'
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1116, 1)
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Order By BranchID
Go

Use Merch
Go

Update Setup.Config
Set Value = '1103,1104,1116,1120,1138,1178'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go

Print '-- $$$$ Branch enabled [Waco,Las Vegas,Lubbock] $$$$--'
Go

