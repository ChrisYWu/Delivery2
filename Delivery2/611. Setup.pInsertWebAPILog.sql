USE [Merch]
GO

/****** Object:  StoredProcedure [Setup].[pInsertWebAPILog]    Script Date: 2/22/2018 3:49:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE Setup.pInsertWebAPILog( @ServiceName   VARCHAR(150),
                                            @OperationName VARCHAR(50),
                                            @ModifiedDate  DATETIME,
                                            @GSN           VARCHAR(50)      = NULL,
                                            @Type          VARCHAR(50)      = NULL,
                                            @Exception     VARCHAR(MAX)     = NULL,
                                            @GUID          UNIQUEIDENTIFIER,
                                            @ComputerName  VARCHAR(50)      = NULL,
                                            @UserAgent     VARCHAR(50)      = NULL,
											@Json		   varchar(max)		= Null,
											@CorrelationID varchar(32)      = null
)
AS

BEGIN 
	 INSERT INTO Setup.WebAPILog
         ([ServiceName],
          [OperationName],
          [ModifiedDate],
          [GSN],
          [Type],
          [Exception],
          [GUID],
          [ComputerName],
		  [UserAgent],
		  Json,
		  CorrelationID,
		  ServerInsertTime
         )
         VALUES
         (@ServiceName,
          @OperationName,
          @ModifiedDate,
          @GSN,
          @Type,
          @Exception,
          @GUID,
          @ComputerName,
		  @UserAgent,
		  @Json,
		  @CorrelationID,
		  SysDateTime()
         );


END

GO

