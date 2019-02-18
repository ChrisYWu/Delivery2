Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

/*
0107	201902070933	5mins -- need to redo
0108	201902070959    7mins -- need to redo
.
.
.
0205    201902081100	6mins -- all done
0101	201902081400
0102    201902081400
0103    201902081400
*/

Declare @StartDate Date, @EndDate Date
Set @StartDate = '2018-11-18'
Set @EndDate = '2018-11-19'

While @StartDate < @EndDate
Begin

	Declare @Query nVarchar(2000)
	Set @Query = 'Insert Into Smart.SalesHistory Select * From OpenQuery(' 
	Set @Query += 'RM' +  ', ''';
	Set @Query += 'SELECT IV.DELIVERY_DATE DELIVERY_DATE, '
	Set @Query += 'IV.CUSTOMER_NUMBER ACCOUNT_NUMBER, ID.ITEM_NUMBER, '
	Set @Query += 'SUM(ID.CASEQTY) DELIVERYCASEQTY '
	Set @Query += 'FROM ACEUSER.INVOICE_MASTER IV, ACEUSER.INVOICE_DETAIL ID, ACEUSER.ITEM_MASTER IM  '
	Set @Query += 'WHERE TO_CHAR(IV.DELIVERY_DATE, ''''YYYY-MM-DD'''') = '
	Set @Query +=  dbo.udfConvertToPLSqlTimeFilter(@StartDate)
	Set @Query += ' AND IV.ORDER_STATUS IN (6,7) '
	Set @Query += 'AND IV.INVOICE_NUMBER = ID.INVOICE_NUMBER '             
	Set @Query += 'AND IV.TYPE = ''''D'''' '
	Set @Query += 'AND ID.CASEQTY > 0 '
	Set @Query += 'AND ID.ITEM_NUMBER = IM.ITEM_NUMBER '
	Set @Query += 'AND IV.LOCATION_ID = IM.LOCATION_ID '
	Set @Query += 'AND IM.MATERIAL_TYPE IN (''''FERT'''', ''''HAWA'''') '
	Set @Query += 'GROUP BY IV.LOCATION_ID, IV.CUSTOMER_NUMBER, IV.DELIVERY_DATE, ID.ITEM_NUMBER '
	Set @Query += ''')'	

	Select(@StartDate)
	Exec(@Query)

	Select @StartDate = DateAdd(Day, 1, @StartDate)
End
Go


Select DeliveryDate, Count(*) Cnt, DATENAME(dw, DeliveryDate) DayOfWeek
From Smart.SalesHistory 
Group By DeliveryDate
Order By DeliveryDate