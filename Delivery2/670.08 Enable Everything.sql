Select @@SERVERNAME Server
Go

Use Portal_Data
Go
Select DB_Name() As [Database]
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Select 6, SAPBranchID, 1
From SAP.Branch b
Where SAPBranchID Not In
(Select BranchID
From Shared.Feature_Authorization fa 
Where FeatureID = 6 )
And SAPBranchID <> 'TJW1'
Order By SAPBranchID
Go

Use Merch
Go
Select DB_Name() As [Database]
Go

Declare @Runner Varchar(4000)
Set @Runner = ''

Select @Runner = @Runner + ',' + SAPBranchID
From SAP.Branch b
Where SAPBranchID != 'TJW1'
Order By SAPBranchID

Select Substring(@Runner, 2, 4000) AllBranches

Update Setup.Config
Set Value = Substring(@Runner, 2, 4000) 
Where ConfigID = 4
Go
