Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Declare @Sales Table 
(
	SaleDate Date, SAPAccount Int, SKU Int, Qty Float
)

Declare @DateTable Table (Value Date)
Declare @RunnerDate Date
Declare @EndDate Date
Declare @ObservationDate Date 

Set @ObservationDate = '1-2-2019'

Select SaleDate Date, SKU, Qty 
From dbo.SalesHistory
Where SAPAccount = 12274874
And SKU=10000862
Order by SaleDate

Set @RunnerDate = DateAdd(Day, -90, @ObservationDate)
Set @EndDate = DateAdd(Day, -1, @ObservationDate)

While @EndDate >= @RunnerDate 
Begin
	Insert Into @DateTable Values (@RunnerDate) 
	Select @RunnerDate = DateAdd(Day, 1, @RunnerDate)
End

--Select * From @DateTable 

Insert Into @Sales
Select a.Value, b.SAPAccount, b.SKU, 0
From @DateTable a
Cross Join
(
	Select Distinct SAPAccount, SKU
	From dbo.SalesHistory
	Where SAPAccount = 12274874
	And SKU=10000862
) b

Update a
Set a.Qty = b.Qty
From @Sales a
Join 
(Select SaleDate, SAPAccount, SKU, SUM(Qty) Qty From dbo.SalesHistory
Group By SaleDate, SAPAccount, SKU) b on a.SaleDate = b.SaleDate And a.SAPAccount = b.SAPAccount And a.SKU = b.SKU

Update @Sales
Set Qty = 0
Where Qty < 0

--Select SaleDate, Qty From @Sales Order by SaleDate

---------------
Truncate Table dbo.Sample

Insert Into dbo.Sample
Select * From @Sales 

Select * From dbo.Sample
Select Sum(Qty) Total From dbo.Sample

Select Distinct 
SAPAccount, SKU,
AVG(Qty) Over(Partition By SAPAccount, SKU) AvgQty,
STDEV(Qty) Over(Partition By SAPAccount, SKU) STDEVQty,
STDEV(Qty) Over(Partition By SAPAccount, SKU)/SQRT(90) StandardError,
STDEV(Qty) Over(Partition By SAPAccount, SKU)/SQRT(90) * 1.440 ConfidenceInterval
From dbo.Sample

--Select 0.6636609888/(3.8700176584098/Sqrt(92))
----- = 1.64485362694069, this is the same as 1.645

--Select SQrt(90)


--Select 1.645/Sqrt(90) --90Factor

--Select 1.645/Sqrt(92) * 3.8700176584098


Select Distinct SESSION_DATE
From Apacheta.FleetLoader
Where SESSION_DATE > '2018-12-31'
And LOCATION_ID = '12274874'
order by SESSION_DATE 
