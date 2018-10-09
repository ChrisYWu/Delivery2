Use Portal_Data
Go

Drop Table Shared.ImageTobeDeleted
Go

Create Table Shared.ImageTobeDeleted
(
	ID int identity(1,1) Primary Key,
	ImageURL varchar(200),
	SourceTable varchar(100),
	IDInSourceTable varchar(20),
	RecordDeletionDate DateTime2(4),
	DBServer varchar(100),
	DBName varchar(100),
	LastModified DateTime2(4)
)
Go
