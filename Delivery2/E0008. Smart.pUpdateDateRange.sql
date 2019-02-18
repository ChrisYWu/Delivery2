Use Portal_Data
Go

Set NoCount On
Go

If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpdateDateRange' and s.name = 'Smart')
Begin
	Drop proc Smart.pUpdateDateRange
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pUpdateDateRange'
End 
Go

Create Proc Smart.pUpdateDateRange
As
Begin
	Set NoCount On;
	Declare @StartDate Date
	Declare @EndDate Date
	Set @EndDate = Convert(Date, SysDateTime()) -- Today
	Set @StartDate = DateAdd(Day, -90, Convert(Date, SysDateTime())) -- 90 Days Range

	While @StartDate < @EndDate -- The Range is close on the smaller end and open on the larger, so it's 90 days counter from yesterday
	Begin
		If Not Exists (Select * From Smart.DeliveryDateRange Where DeliveryDate = @StartDate)
		Begin
			Insert Smart.DeliveryDateRange(DeliveryDate, RecordCount, InRange)
			Values(@StartDate, 0, 1)
		End
		Select @StartDate = DateAdd(Day, 1, @StartDate)
	End

	Update r
	Set r.RecordCount = h.Cnt
	From 
	Smart.DeliveryDateRange r
	Join
		(
		Select DeliveryDate, Count(*) Cnt
		From Smart.SalesHistory   
		Group By DeliveryDate
	) h on r.DeliveryDate = h.DeliveryDate

	Set @StartDate = DateAdd(Day, -90, Convert(Date, SysDateTime())) -- 90 Days Range
	Update Smart.DeliveryDateRange
	Set InRange = 0
	Where DeliveryDate < @StartDate

	Select 'Deleting Smart.SalesHistory for delivery date < ' + convert(Varchar(10), @StartDate)

	Delete Smart.SalesHistory
	Where DeliveryDate < @StartDate
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pUpdateDateRange created'
Go

--exec Smart.pUpdateDateRange
--Go

