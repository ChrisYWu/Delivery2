Use Merch
Go

Select @@SERVERNAME Server
Go

Select DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName like 'Lub%'

-------------------------------------------
Use Portal_Data
Go

Select *
From SAP.Branch Where BranchName = 'Lubbock'
And SAPBranchID = '1178'
Go

Delete Shared.Feature_Authorization
Where FeatureID = 6
And BranchID = 1178
And IsActive = 1
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Order By BranchID
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

Print '-- $$$$ Branch enabled [Waco,Las Vegas] $$$$--'
Go