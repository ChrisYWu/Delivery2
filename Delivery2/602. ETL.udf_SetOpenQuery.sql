USE Merch
GO

If Exists (Select * From sys.objects Where name = 'udf_SetOpenQuery' And Type = 'FN')
Begin
	Drop Function ETL.udf_SetOpenQuery
	Print '* ETL.udf_SetOpenQuery'
End
Go

----------------------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Function ETL.udf_SetOpenQuery
(
	@Query Varchar(1024),
	@LinkedServerName Varchar(20) = 'COP',
	@InputTime DateTime
)
Returns Varchar(1024)
As
	Begin
		Declare @retval varchar(1024)
		Set @retval = 'Select * From OpenQuery(' 
		Set @retval += @LinkedServerName +  ', ''';
		Set @retval += @Query;
		Set @retval += ' ' + ETL.udf_ConvertToPLSqlTimeFilter(@InputTime, Default)
		Set @retval += ''')'

		Return @retval
	End
Go

Print 'Function ETL.udf_SetOpenQuery created'
Go


-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
If Exists (Select * From sys.objects Where name = 'udf_ConvertToPLSqlTimeFilter' And Type = 'FN')
Begin
	Drop Function ETL.udf_ConvertToPLSqlTimeFilter
	Print '* ETL.udf_ConvertToPLSqlTimeFilter'
End
Go

----------------------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function ETL.udf_ConvertToPLSqlTimeFilter
(
	@InputTime DateTime,
	@ObjectAlias Varchar(20) = null
)
Returns Varchar(200)
As
	Begin
		Declare @retval varchar(200)
		Set @retval = 'WHERE '
		If (IsNUll(@ObjectAlias, '') <> '')
			Set @retval += @ObjectAlias + '.'
		Set @retval += 'DATE_MODIFIED > TO_DATE('''''
		Set @retval += convert(varchar, @InputTime, 120)
		Set @retval += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'

		Return @retval
	End
GO

Print 'Function ETL.udf_ConvertToPLSqlTimeFilter created'
Go

-------------------------------------------------------------
-------------------------------------------------------------
-------------------------------------------------------------
If Exists (Select * From sys.objects Where name = 'udf_TitleCase' And Type = 'FN')
Begin
	Drop Function dbo.udf_TitleCase
	Print '* dbo.udf_TitleCase'
End
Go

----------------------------------------------------------------

CREATE FUNCTION dbo.udf_TitleCase (@InputString VARCHAR(4000) )
RETURNS VARCHAR(4000)
AS
 BEGIN
 DECLARE @Index INT
 DECLARE @Char CHAR(1)
DECLARE @OutputString VARCHAR(255)
SET @OutputString = LOWER(@InputString)
SET @Index = 2
SET @OutputString =
STUFF(@OutputString, 1, 1,UPPER(SUBSTRING(@InputString,1,1)))
WHILE @Index <= LEN(@InputString)
BEGIN
 SET @Char = SUBSTRING(@InputString, @Index, 1)
IF @Char IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&','''','(')
IF @Index + 1 <= LEN(@InputString)
BEGIN
 IF @Char != ''''
OR
UPPER(SUBSTRING(@InputString, @Index + 1, 1)) != 'S'
SET @OutputString =
STUFF(@OutputString, @Index + 1, 1,UPPER(SUBSTRING(@InputString, @Index + 1, 1)))
END
 SET @Index = @Index + 1
END
 RETURN ISNULL(@OutputString,'')
END 

GO

Print 'Function dbo.udf_TitleCase created'
Go

----------------------------------------------
If Not Exists (Select * From sys.schemas Where Name = 'Mesh')
Begin
	exec(N'Create Schema Mesh')
	Print 'Schema Mesh created'
End

Go

If Not Exists (Select * From sys.schemas Where Name = 'Archive')
Begin
	exec(N'Create Schema Archive')
	Print 'Schema Archive created'
End

Go

----------------------------------------------
If Exists (Select * From sys.tables Where Name = 'DeliveryRoute')
Begin
	Drop Table [Mesh].[DeliveryRoute]
	Print '* Mesh.DeliveryRoute'
End 

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [Mesh].[DeliveryRoute](
	[PKEY] [bigint] NOT NULL,
	[RouteID] [int] NOT NULL,
	[PlannedStartTime] [datetime2](0) NOT NULL,
	[IsStarted]  AS (CONVERT([bit],case when [ActualStartTime] IS NULL then (0) else (1) end)),
	[SAPBranchID] [int] NOT NULL,
	FirstName nvarchar(200),
	Lastname nvarchar(200),
	PhoneNumber nvarchar(50),
	[PlannedCompleteTime] [datetime2](0) NOT NULL,
	[PlannedTravelTime] [int] NOT NULL,
	[PlannedServiceTime] [int] NOT NULL,
	[PlannedBreakTime] [int] NOT NULL,
	[PlannedPreRouteTime] [int] NOT NULL,
	[PlannedPostRouteTime] [int] NOT NULL,
	[ActualStartTime] [datetime2](0) NULL,
	[ActualCompleteTime] [datetime2](0) NULL,
	[LastModifiedBy] [varchar](50) NOT NULL,
	[LastModifiedUTC] [datetime2](0) NOT NULL,
	CONSTRAINT [PK_DeliveryRoute] PRIMARY KEY CLUSTERED 
(
	[PKEY] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING OFF
GO

Print 'Table Mesh.DeliveryRoute created'
GO

----------------------------------------------
If Exists (Select * From sys.tables t join sys.schemas s on t.schema_id = s.schema_id Where t.Name = 'DeliveryRoute' and s.name = 'Archive')
Begin
	Drop Table [Archive].[DeliveryRoute]
	Print '* Archive.DeliveryRoute'
End 

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE Archive.DeliveryRoute(
	[PKEY] [bigint] NOT NULL,
	[RouteID] [int] NOT NULL,
	[PlannedStartTime] [datetime2](0) NOT NULL,
	[IsStarted]  AS (CONVERT([bit],case when [ActualStartTime] IS NULL then (0) else (1) end)),
	[SAPBranchID] [int] NOT NULL,
	FirstName nvarchar(200),
	Lastname nvarchar(200),
	PhoneNumber nvarchar(50),
	[PlannedCompleteTime] [datetime2](0) NOT NULL,
	[PlannedTravelTime] [int] NOT NULL,
	[PlannedServiceTime] [int] NOT NULL,
	[PlannedBreakTime] [int] NOT NULL,
	[PlannedPreRouteTime] [int] NOT NULL,
	[PlannedPostRouteTime] [int] NOT NULL,
	[ActualStartTime] [datetime2](0) NULL,
	[ActualCompleteTime] [datetime2](0) NULL,
	[LastModifiedBy] [varchar](50) NOT NULL,
	[LastModifiedUTC] [datetime2](0) NOT NULL,
	CONSTRAINT [PK_DeliveryRoute] PRIMARY KEY CLUSTERED 
(
	[PKEY] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING OFF
GO

Print 'Table Mesh.DeliveryRoute created'
GO



