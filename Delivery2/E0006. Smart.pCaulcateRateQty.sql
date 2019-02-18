Use Portal_Data
Go

Set NoCount On
Go


------------------------------------------------------------
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pCaulcateRateQty' and s.name = 'Smart')
Begin
	Drop proc Smart.pCaulcateRateQty
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pCaulcateRateQty'
End 
Go

Create Proc Smart.pCaulcateRateQty
(
	@ZScore Float = 0.842,   --This is Z60
	@SampleSize int = 90
)
As 
Begin
	Set NoCount On

	Declare @Bessel Int
	Set @Bessel = @SampleSize - 1

	Truncate Table Smart.Daily
	--@@@@--
	Drop Index NCI_SmartDaily_Rate ON Smart.Daily

	Insert Into Smart.Daily(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, Sum(Quantity)/@SampleSize Mean
	From Smart.SalesHistory
	Group By SAPAccountNumber, SAPMaterialID;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Square(h.Quantity - d.Mean) SQR
		From Smart.SalesHistory h
		Join Smart.Daily d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.DiffSQR = t.DiffSQR
	From Smart.Daily d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(SQR) DiffSQR
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	-- Sqrt(90) = 9.48683298050514
	Update Smart.Daily
	Set Comp = (@SampleSize - Cnt) * Square(Mean)

	Update Smart.Daily
	Set STD = Sqrt((DiffSQR + Comp)/@Bessel)

	Update Smart.Daily
	Set Error = STD/9.48683298050514, Rate = Mean - @Zscore*STD/9.48683298050514, Modified = SysDateTime()

	--@@@@--
	Create NONCLUSTERED INDEX NCI_SmartDaily_Rate ON Smart.Daily
	(
		SAPAccountNumber ASC
	)
	INCLUDE (SAPMaterialID, Rate)
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pCaulcateRateQty created'
Go

--exec Smart.pCaulcateRateQty
--Go

------------------------------------------------------------
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pCaulcateRateQty1' and s.name = 'Smart')
Begin
	Drop proc Smart.pCaulcateRateQty1
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pCaulcateRateQty1'
End 
Go

Create Proc Smart.pCaulcateRateQty1
(
	@ZScore Float = 0.842,   --This is Z60
	@SampleSize int = 90
)
As 
Begin
	Set NoCount On

	Declare @Bessel Int
	Set @Bessel = @SampleSize - 1

	Truncate Table Smart.Daily1
	--@@@@--
	Drop Index NCI_SmartDaily1_Rate ON Smart.Daily1

	Insert Into Smart.Daily1(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, Sum(Quantity)/@SampleSize Mean
	From Smart.SalesHistory
	Group By SAPAccountNumber, SAPMaterialID;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Square(h.Quantity - d.Mean) SQR
		From Smart.SalesHistory h
		Join Smart.Daily1 d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.DiffSQR = t.DiffSQR
	From Smart.Daily1 d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(SQR) DiffSQR
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	-- Sqrt(90) = 9.48683298050514
	Update Smart.Daily1
	Set Comp = (@SampleSize - Cnt) * Square(Mean)

	Update Smart.Daily1
	Set STD = Sqrt((DiffSQR + Comp)/@Bessel)

	Update Smart.Daily1
	Set Error = STD/9.48683298050514, Rate = Mean - @Zscore*STD/9.48683298050514, Modified = SysDateTime()

	--@@@@--
	Create NONCLUSTERED INDEX NCI_SmartDaily1_Rate ON Smart.Daily1
	(
		SAPAccountNumber ASC
	)
	INCLUDE (SAPMaterialID, Rate)
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pCaulcateRateQty1 created'
Go