Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Config' and s.name = 'Smart')
Begin
	Drop Table Smart.Config
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.Config'
End
Go

Create Table Smart.Config
( 
	ConfigID int Primary Key,
	Descr varchar(128),
	Designation varchar(max),
	LastModified DateTime2(0)
)
Go

Insert Into Smart.Config
Values(1, 'Live indicator', '0', SysDateTime())

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.Config created and initialized'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select *  From Shared.Feature_Master Where FeatureID = 8)
Begin
	Set IDENTITY_INSERT Shared.Feature_Master On
	Insert Into Shared.Feature_Master(FeatureID, FeatureName, ApplicationID, IsActive, IsCustomized)
	Values(8, 'SMARTORDER', 1, 1, 1)
	Set IDENTITY_INSERT Shared.Feature_Master Off

	Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
	Select 8, SAPBranchID, 1
	From SAP.Branch b
	Where SAPBranchID Not In
	(Select BranchID
	From Shared.Feature_Authorization fa 
	Where FeatureID = 6 )
	And SAPBranchID <> 'TJW1'
	Order By SAPBranchID
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Feature SMARTORDER added and initialized with all branches'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'ChainExclusion' and s.name = 'Smart')
Begin
	Drop Table Smart.Config
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.ChainExclusion'
End
Go

Create Table Smart.ChainExclusion
( 
	ExclusionID int Identity(1,1) Primary Key,
	NationalChainID Int Null,
	RegionalChainID Int Null,
	LocalChainID Int Null,
	LastModified DateTime2(0) Default SysDateTime()
)
Go

Insert Into Smart.ChainExclusion(NationalChainID) Values (60)

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.ChainExclusion created and initialized(Walmart added)'
Go

