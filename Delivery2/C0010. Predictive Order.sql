use Merch
Go

/*
1. Negative Qty is ignored for calculating AVG
2. Negative Qty is not ignored for calculating STDDev

*/

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [Route Number]
      ,[Route Description]
      ,[Customer Number]
      ,[Customer Description]
      ,[SKU]
      ,[SKU Description]
      ,[Daily Average]
      ,[StDev]
      ,[90% Confidence Interval for Mean]
      ,[Lower end Conf# Int#]
      ,[Upper end Conf# Int#]
      ,[Build To]
      ,[Layer Build-To]
      ,[85% Confidence]
      ,[Lower end]
      ,[Upper end]
      ,[85% Build-To Base]
      ,[Layer Build-To 85%]
      ,[F19]
      ,[F20]
      ,[F21]
  FROM [Merch].[dbo].[Build To]
  Where [Customer Number] =  12274874
  And SKU=10000862

Select Convert(Date, [Date]) SaleDate, [Customer Number] SAPAccount, SKU, [Sales Qty] Qty
From dbo.PasteData 
Where [Customer Number] = 12274874
And SKU=10000862

Drop Table dbo.SalesHistory

Select Convert(Date, [Date]) SaleDate, [Customer Number] SAPAccount, SKU, [Sales Qty] Qty
Into dbo.SalesHistory
From dbo.PasteData 

-- customer number = 12274874
Select Min(Date) MinDate, Max(Date) MaxDate, DateDiff(Day, Min(Date), Max(Date))
From dbo.PasteData 
Where [Customer Number] = 12274874
And SKU=10000862

Select Sum([Sales Qty]) / 92, Sum([Sales Qty]) 
From dbo.PasteData 
Where [Customer Number] = 12274874
And SKU=10000862

Select 1.54891304347826*92

Select *
From dbo.PasteData 
Where [Customer Number] = 12274874
And SKU=10000862
Order By Date
Go

------------------------------------
--Select Convert(Date, [Date]) SaleDate, [Customer Number] SAPAccount, SKU, [Sales Qty] Qty
--Into dbo.SalesHistory
--From dbo.PasteData 

--Alter Table dbo.SalesHistory
--Add OriQty Int

--Update dbo.SalesHistory
--Set OriQty = Qty 

--Update dbo.SalesHistory
--Set Qty = 0
--Where Qty < 0

--Drop Table dbo.Sample

--Create Table dbo.Sample(SaleDate Date, SAPAccount Int, SKU Int, Qty Float)

--Delete dbo.SalesHistory
--Where SaleDate is null
--And SAPAccount is null
--And SKU is null
--And Qty is null

--------------------------------------
--------------------------------------
Declare @Sales Table 
(
	SaleDate Date, SAPAccount Int, SKU Int, Qty Int
)

Declare @DateTable Table (Value Date)
Declare @RunnerDate Date
Declare @EndDate Date

Select @RunnerDate = Min(SaleDate), @EndDate = Max(SaleDate)
From dbo.SalesHistory

While @EndDate >= @RunnerDate 
Begin
	Insert Into @DateTable Values (@RunnerDate) 
	Select @RunnerDate = DateAdd(Day, 1, @RunnerDate)
End

Delete @DateTable 
Insert @DateTable 
Select Distinct SaleDate From dbo.SalesHistory

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

Truncate Table dbo.Sample

Insert Into dbo.Sample
Select * From @Sales 

Select *
From dbo.Sample Order By SaleDate

Delete dbo.Sample 
Where Qty = 0

Select Sum(Qty) Sum1
From dbo.Sample

Select Distinct 
SAPAccount, SKU,
AVG(Qty) Over(Partition By SAPAccount, SKU) AvgQty, 
STDEV(Qty) Over(Partition By SAPAccount, SKU) STDEVQty 
From dbo.Sample

--3.6713665826596
--1.58333333333333

Select Distinct 
SAPAccount, SKU,
AVG(Qty) Over(Partition By SAPAccount, SKU) AvgQty, 
--STDEV(Qty) Over(Partition By SAPAccount, SKU) STDEVQty 
3.8700177 STDEVQty,
SQRT(Square(3.8700176584098)/92.0) StandardError, 
SQRT(Square(3.8700176584098)/92.0) * 1.645 As Pct90ConfidenceInterval,
SQRT(Square(3.8700176584098)/92.0) * 1.440 As Pct85ConfidenceInterval
From dbo.Sample

Select 0.6636609888/(3.8700176584098/Sqrt(92))
Select 0.58081817/(3.8700176584098/Sqrt(92))
--- = 1.64485362694069, this is the same as 1.645

Select SQrt(90)


Select 1.645/Sqrt(90) --90Factor

Select 1.645/Sqrt(92) * 3.8700176584098

Select 

