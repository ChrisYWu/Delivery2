Use Merch
Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select *
	From Sys.columns c join sys.tables t on c.object_id = t.object_id
	Where c.name = 'TimeZoneOffSet' and t.name = 'Merchandiser')
Begin
	Alter Table Setup.Merchandiser
	Add TimeZoneOffSet Int Null

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Column TimeZoneOffSet added to table Setup.Merchandiser'
End
Go

Update Setup.Merchandiser
Set TimeZoneOffset = 0

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Column TimeZoneOffSet initialized'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
ALTER PROCEDURE Operation.pUpsertMerchPhoneNumber
(
	@GSN Varchar(50),
	@PhoneNumber Varchar(50),
	@TimeZoneOffSet int = 0
)

AS

BEGIN 
	UPDATE Setup.Merchandiser 
		SET Phone = @PhoneNumber, TimeZoneOffSet = @TimeZoneOffSet
	WHERE GSN = @GSN
END
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Procedure Operation.pUpsertMerchPhoneNumber updated'
Go
