Use Portal_Data
Go

Set NoCount On
Go

Select Top 1 SAPAccountNumber
From Smart.SalesHistory
Where SAPAccountNumber / 10000000 = 5
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
As 
Begin
	Set NoCount On

	Truncate Table Smart.Daily
	Drop INDEX NCI_SmartDaily_Rate ON Smart.Daily

	--@@@@--
	Insert Into Smart.Daily(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean, STD)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, AVG(Quantity) Mean, STDEV(Quantity) STD
	From Smart.SalesHistory
	Where SAPAccountNumber / 10000000 <> 5
	Group By SAPAccountNumber, SAPMaterialID
	Having Count(*) > 4;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Case When h.Quantity < d.Cap Then h.Quantity Else Cap End Capped
		From Smart.SalesHistory h
		Join Smart.Daily d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.Sum2 = t.Sum2, d.Rate = t.Sum2/90.0, d.Modified = SysDateTime()
	From Smart.Daily d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(Capped) Sum2
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate ON Smart.Daily
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
As 
Begin
	Set NoCount On

	Truncate Table Smart.Daily1
	Drop INDEX NCI_SmartDaily_Rate1 ON Smart.Daily1
	--@@@@--

	Insert Into Smart.Daily1(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean, STD)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, AVG(Quantity) Mean, STDEV(Quantity) STD
	From Smart.SalesHistory
	Where SAPAccountNumber / 10000000 <> 5
	Group By SAPAccountNumber, SAPMaterialID
	Having Count(*) > 4;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Case When h.Quantity < d.Cap Then h.Quantity Else Cap End Capped
		From Smart.SalesHistory h
		Join Smart.Daily d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.Sum2 = t.Sum2, d.Rate = t.Sum2/90.0, d.Modified = SysDateTime()
	From Smart.Daily1 d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(Capped) Sum2
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate1 ON Smart.Daily1
	(
		SAPAccountNumber ASC
	)
	INCLUDE (SAPMaterialID, Rate)

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pCaulcateRateQty1 created'
Go

--exec Smart.pCaulcateRateQty1
--Go

--exec Smart.pCaulcateRateQty
--Go


