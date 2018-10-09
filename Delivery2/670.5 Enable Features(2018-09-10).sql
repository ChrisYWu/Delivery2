Use Portal_Data
Go

Select *
From SAP.Branch Where BranchName = 'Las Vegas'
And SAPBranchID = '1138'
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1138, 1)
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
