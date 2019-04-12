Use Portal_Data
Go

Set NoCount On;
Go

If Not Exists (
	Select *
	From sys.columns c
	Join sys.tables t on c.object_id = t.object_id
	Where c.name = 'Source'
	And t.name = 'VoidOrderTracking'
)
Begin
	Alter Table DNA.VoidOrderTracking
	Add Source Varchar(128)

	CREATE NONCLUSTERED INDEX NCI_VoidOrderTracking_Source ON DNA.VoidOrderTracking
	(
		Source ASC
	)

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  'Adding column Source to table DNA.VoidOrderTracking'
End
Go

Drop Proc DNA.pInsertVoidOrderDetails
Go
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  '* Proc DNA.pInsertVoidOrderDetails dropped'
Go

DROP TYPE DNA.utd_Void_OrderTracking
GO
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  '* Type DNA.utd_Void_OrderTracking dropped'
Go

CREATE TYPE DNA.utd_Void_OrderTracking AS TABLE(
	OrderNumber nvarchar(15) NOT NULL,
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	ProposedQty int NOT NULL,
	OrderedQty int NOT NULL,
	VoidReasonCodeID int NOT NULL,
	OrderedBy varchar(50) NOT NULL,
	OrderDate datetime NOT NULL,
	Comments varchar(250) NULL,
	Source varchar(128) NULL,
	PRIMARY KEY CLUSTERED 
	(
		OrderNumber ASC,
		SAPMaterialID ASC
	) WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Type DNA.utd_Void_OrderTracking created'
Go

If Exists (
	Select *
	From sys.tables t
	Join sys.schemas s on t.schema_id = s.schema_id
	Where t.name = 'OrderTrackingHistory'
	And s.name = 'Smart'
)
Begin
	Drop Table [Smart].OrderTrackingHistory

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Table Smart.OrderTrackingHistory dropped'
End
Go

CREATE TABLE [Smart].[OrderTrackingHistory](
	[OrderNumber] [nvarchar](15) NOT NULL,
	[SAPAccountNumber] [bigint] NOT NULL,
	[SAPMaterialID] [varchar](12) NOT NULL,
	[ProposedQty] [int] NOT NULL,
	[OrderedQty] [int] NOT NULL,
	[VoidReasonCodeID] [int] NOT NULL,
	[OrderedBy] [varchar](50) NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[InsertedBy] [varchar](50) NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[Comments] [varchar](250) NULL,
	[Source] [varchar](128) NULL,
 CONSTRAINT [PK_OrderTrackingHistory] PRIMARY KEY CLUSTERED 
(
	[OrderNumber] ASC,
	[SAPMaterialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.OrderTrackingHistory created'
Go

If Exists (
	Select *
	From sys.tables t
	Join sys.schemas s on t.schema_id = s.schema_id
	Where t.name = 'OrderTracking'
	And s.name = 'Smart'
)
Begin
	Drop Table [Smart].[OrderTracking]

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Table Smart.OrderTracking dropped'
End
Go

CREATE TABLE [Smart].[OrderTracking](
	[OrderNumber] [nvarchar](15) NOT NULL,
	[SAPAccountNumber] [bigint] NOT NULL,
	[SAPMaterialID] [varchar](12) NOT NULL,
	[ProposedQty] [int] NOT NULL,
	[OrderedQty] [int] NOT NULL,
	[VoidReasonCodeID] [int] NOT NULL,
	[OrderedBy] [varchar](50) NOT NULL,
	[OrderDate] [datetime] NOT NULL,
	[InsertedBy] [varchar](50) NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[Comments] [varchar](250) NULL,
	[Source] [varchar](128) NULL,
 CONSTRAINT [PK_OrderTracking] PRIMARY KEY CLUSTERED 
(
	[OrderNumber] ASC,
	[SAPMaterialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [Smart].[OrderTracking]  WITH CHECK ADD  CONSTRAINT [FK_OrderTracking_VoidReasonCode_VoidReasonCodeID] FOREIGN KEY([VoidReasonCodeID])
REFERENCES [DNA].[VoidReasonCode] ([VoidReasonCodeID])
GO

ALTER TABLE [Smart].[OrderTracking] CHECK CONSTRAINT [FK_OrderTracking_VoidReasonCode_VoidReasonCodeID]
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.OrderTracking created'
Go

Create PROCEDURE DNA.pInsertVoidOrderDetails(@tvpTable DNA.utd_Void_OrderTracking READONLY)
AS
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN
            --BEGIN TRAN UploadVoidOrder;
            DECLARE @SD INT;

			INSERT Smart.OrderTracking(OrderNumber,
                    SAPAccountNumber,
                    SAPMaterialID,
                    ProposedQty,
                    OrderedQty,
                    VoidReasonCodeID,
                    OrderedBy,
                    OrderDate,
                    InsertedBy,
                    InsertDate,
					Comments,
					Source)
			Select 	OrderNumber,
                    SAPAccountNumber,
                    SAPMaterialID,
                    ProposedQty,
                    OrderedQty,
                    VoidReasonCodeID,
                    OrderedBy,
                    OrderDate,
					'System',
					GETDATE(),
					Comments,
					Source
			From @tvpTable
			Where Source in ('PREDICTIVE', 'SMART')

			Declare @tvpTable2 DNA.utd_Void_OrderTracking
			Insert @tvpTable2 
			Select * From @tvpTable
			Where Source not in ('PREDICTIVE', 'SMART')

            MERGE INTO DNA.VoidOrderTracking AS C1
            USING @tvpTable2 AS C2
            ON(C1.OrderNumber = C2.OrderNumber
               AND C1.SAPAccountNumber = C2.SAPAccountNumber
               AND C1.SAPMaterialID = C2.SAPMaterialID)
                WHEN MATCHED
                THEN UPDATE SET
                    C1.ProposedQty = C2.ProposedQty,
                    C1.OrderedQty = C2.OrderedQty,
                    C1.VoidReasonCodeID = C2.VoidReasonCodeID,
                    C1.OrderedBy = C2.OrderedBy,
                    C1.OrderDate = C2.OrderDate,
                    C1.InsertedBy = 'System',
                    C1.InsertDate = GETDATE(),
					C1.Comments = C2.Comments,
					C1.Source = Case When C2.Source is null Then 'POG' When RTRIM(LTRIM(C2.Source)) = '' Then 'POG' Else C2.Source End 
                WHEN NOT MATCHED
                THEN INSERT(OrderNumber,
                    SAPAccountNumber,
                    SAPMaterialID,
                    ProposedQty,
                    OrderedQty,
                    VoidReasonCodeID,
                    OrderedBy,
                    OrderDate,
                    InsertedBy,
                    InsertDate,
					Comments,
					Source) VALUES
            (C2.OrderNumber,
             C2.SAPAccountNumber,
             C2.SAPMaterialID,
             C2.ProposedQty,
             C2.OrderedQty,
             C2.VoidReasonCodeID,
             C2.OrderedBy,
             C2.OrderDate,
             'System',
             GETDATE(),
			 C2.Comments,
			 Case When C2.Source is null Then 'POG' When RTRIM(LTRIM(C2.Source)) = '' Then 'POG' Else C2.Source End
            );

            MERGE INTO DNA.Snoozing AS C1
            USING @tvpTable2 AS C2
            ON(C1.SAPAccountNumber = C2.SAPAccountNumber
               AND C1.SAPMaterialID = C2.SAPMaterialID)
                WHEN MATCHED
                THEN UPDATE SET
                                C1.InsertedBy = 'System',
                                C1.InsertDate = GETDATE(),
                                C1.SnoozeDate =
            (
                SELECT DATEADD(day, SnoozeDuration, GETDATE())
                FROM DNA.VoidReasonCode
                WHERE VoidReasonCodeId = C2.VoidReasonCodeID
            )
                WHEN NOT MATCHED
                THEN INSERT(SAPAccountNumber,
                            SAPMaterialID,
                            InsertedBy,
                            InsertDate,
                            SNOOZEDATE) VALUES
            (C2.SAPAccountNumber,
             C2.SAPMaterialID,
             'System',
             GETDATE(),
            (
                SELECT DATEADD(day, SnoozeDuration, GETDATE())
                FROM DNA.VoidReasonCode
                WHERE VoidReasonCodeId = C2.VoidReasonCodeID
            )
            );

            --COMMIT TRAN UploadVoidOrder;
        END;
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(2048)= ERROR_MESSAGE(), @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        RAISERROR(@msg, 16, 1);
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
    END CATCH;
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc DNA.pInsertVoidOrderDetails created'
Go

Update DNA.VoidOrderTracking
Set Source = 'POG'
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Column [Source] on table DNA.VoidOrderTracking updated with default value POG'
Go
