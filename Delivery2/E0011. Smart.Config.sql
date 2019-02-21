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
