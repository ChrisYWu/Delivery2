Use Merch
Go

Select @@SERVERNAME Server
Go

Select DB_Name() As [Database]
Go

Select *
From SAP.Branch
Where BranchName like 'Lub%'

--SAPBranchID = 1178


Insert Into Notify.Party
Select GSN, Phone, Null, 'Merchandiser', -5
From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup g on m.MerchGroupID = g.MerchGroupID
Where g.SAPBranchID = 1178
And Phone <> ''
And GSN Not in (Select PartyID From Notify.Party)

-------------------------------------------
Use Portal_Data
Go

Select *
From SAP.Branch Where BranchName = 'Lubbock'
And SAPBranchID = '1178'
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1178, 1)
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Order By BranchID
Go

Use Merch
Go

Update Setup.Config
Set Value = '1002,1120,1138,1178'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go

Print '-- $$$$ Branch enabled [Waco,Las Vegas,Lubbock] $$$$--'
Go