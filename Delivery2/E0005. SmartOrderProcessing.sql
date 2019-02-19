Use Portal_Data
Go

--Select @@SERVERNAME Server, DB_Name() As Database
--Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select * From sys.schemas Where Name = 'Smart')
Begin
	exec('Create Schema Smart')
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'SalesHistory' and s.name = 'Smart')
Begin
	Drop Table Smart.SalesHistory
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.SalesHistory'
End
Go

CREATE TABLE Smart.SalesHistory(
	DeliveryDate date NOT NULL,
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	Quantity float NOT NULL,
	CONSTRAINT PK_SalesHistory PRIMARY KEY CLUSTERED 
	(
		DeliveryDate ASC,
		SAPAccountNumber ASC,
		SAPMaterialID ASC
	)
) 

Go

CREATE NONCLUSTERED INDEX NCI_SmartSalesHistory_Account_Material ON Smart.SalesHistory
(
	SAPAccountNumber ASC,
	SAPMaterialID ASC
)
INCLUDE (Quantity)
GO

CREATE NONCLUSTERED INDEX NCI_SmartSalesHistory_DeliveryDate ON Smart.SalesHistory
(
	DeliveryDate ASC
)
INCLUDE (Quantity)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.SalesHistory created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Daily' and s.name = 'Smart')
Begin
	Drop Table Smart.Daily
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.Daily'
End
Go

CREATE TABLE Smart.Daily(
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	Sum1 float NULL Default(0),
	Cnt int NULL Default(0),
	Mean float NULL Default(0),
	STD float Null Default(0),
	Cap as Mean + STD,
	Sum2 float Null Default(0),
	Rate float NULL Default(0),
	Modified DateTime2(0) Null Default SysDateTime(),
	CONSTRAINT PK_SmartDaily PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC,
		SAPMaterialID ASC
	)
)
Go

CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate ON Smart.Daily
(
	SAPAccountNumber ASC
)
INCLUDE (SAPMaterialID, Rate)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.Daily created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Daily1' and s.name = 'Smart')
Begin
	Drop Table Smart.Daily1
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.Daily1'
End
Go

CREATE TABLE Smart.Daily1(
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	Sum1 float NULL Default(0),
	Cnt int NULL Default(0),
	Mean float NULL Default(0),
	STD float Null Default(0),
	Cap as Mean + STD,
	Sum2 float Null Default(0),
	Rate float NULL Default(0),
	Modified DateTime2(0) Null Default SysDateTime(),
	CONSTRAINT PK_SmartDaily1 PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC,
		SAPMaterialID ASC
	)
)

Go

CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate1 ON Smart.Daily1
(
	SAPAccountNumber ASC
)
INCLUDE (SAPMaterialID, Rate)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.Daily1 created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'DeliveryDateRange' and s.name = 'Smart')
Begin
	Drop Table Smart.DeliveryDateRange
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.DeliveryDateRange'
End
Go

CREATE TABLE Smart.DeliveryDateRange(
	DeliveryDate Date Not Null,
	RecordCount Int,
	InRange bit, 
	DayOfWeek As DATENAME(dw, DeliveryDate),	
	Constraint PK_DeliveryDateRange Primary Key Clustered
	(
		DeliveryDate ASC
	)
)

Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.DeliveryDateRange created'
Go
