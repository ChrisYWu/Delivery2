EXEC sp_addlinkedserver   
   @server=N'MyAzureDb', 
   @srvproduct=N'Azure SQL Db',
   @provider=N'SQLNCLI', 
   @datasrc=N'WUDPSGPOC.DATABASE.WINDOWS.NET,1433',
   @catalog='WuTestDB2017';
GO

--Set up login mapping
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'MyAzureDb', 
    @useself = 'FALSE', 
    @locallogin=NULL,
    @rmtuser = 'chris',
    @rmtpassword = 'Pass@word17'
GO

-- Test the connection
sp_testlinkedserver MyAzureDb;
GO
