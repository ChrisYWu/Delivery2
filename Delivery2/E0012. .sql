Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select s.name
From sys.procedures p
Join sys.schemas s on p.schema_id = s.schema_id
Where p.name = 'pInsertVoidORderDetails'
