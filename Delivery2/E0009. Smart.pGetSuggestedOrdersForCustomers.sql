Use Portal_Data
Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
IF TYPE_ID(N'Smart.tCustomerOrderInput') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetSuggestedOrdersForCustomers' and s.name = 'Smart')
	Begin
		Drop proc Smart.pGetSuggestedOrdersForCustomers
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc Smart.pGetSuggestedOrdersForCustomers'
	End

	Drop Type Smart.tCustomerOrderInput
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* Smart.tCustomerOrderInput'
End
GO

CREATE TYPE Smart.tCustomerOrderInput AS TABLE(
	SAPAccountNumber int not null,
	DeliveryDate Date not null,
	NextDeliveryDate Date not null,
	PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type Smart.tCustomerOrderInput created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetSuggestedOrdersForCustomers' and s.name = 'Smart')
Begin
	Drop proc Smart.pGetSuggestedOrdersForCustomers
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pGetSuggestedOrdersForCustomers'
End 
Go

Create Proc Smart.pGetSuggestedOrdersForCustomers
(
	@SAPAccounts Smart.tCustomerOrderInput ReadOnly,
	@Debug Bit = 0
)
As 
Begin
	Set NoCount On;
	
	Declare @Results Table
	(
		SAPAccountNumber int,
		DeliveryDate Date,
		NumberOfDays Int,
		ItemNumber varchar(20),
		Rate Float,
		RawQty Float,
		SuggestedQty Int
	)

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	Declare @FilteredAccounts Table
	(
		SAPAccountNumber int not null,
		DeliveryDate Date not null,
		NextDeliveryDate Date not null
	)

	Insert Into @FilteredAccounts
	Select *
	From @SAPAccounts;

	With localChainExclusion As (
		Select lc.LocalChainID
		From Smart.ChainExclusion ce
		Join SAP.RegionalChain rc on ce.NationalChainID = rc.NationalChainID
		Join SAP.LocalChain lc on rc.RegionalChainID = lc.RegionalChainID
		Where ce.NationalChainID Is Not Null
		Union
		Select lc.LocalChainID
		From Smart.ChainExclusion ce
		Join SAP.LocalChain lc on ce.RegionalChainID = lc.RegionalChainID
		Where ce.RegionalChainID Is Not Null
		Union
		Select ce.LocalChainID
		From Smart.ChainExclusion ce
		Where ce.LocalChainID Is Not Null
	)

	Delete @FilteredAccounts
	Where SAPAccountNumber In (
		Select SAPAccountNumber 
		From SAP.Account a 
		Join localChainExclusion lc on a.LocalChainID = lc.LocalChainID
	)

	If @Debug = 1
	Begin
		Select 'Accounts after filtered by chains' Step2
		Select * From @FilteredAccounts Order by SAPAccountNumber
	End
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	If Exists (Select * From Smart.Config Where ConfigID = 1 And Designation = 0)
	Begin
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
			+ 'Smart.pGetSuggestedOrdersForCustomers reads from Smart.Daily'
		Insert Into @Results 
		Select d.SAPAccountNumber, a.DeliveryDate, 
			DateDiff(day, DeliveryDate, NextDeliveryDate) NumberOfDays, d.SAPMaterialID, Rate, Rate*DateDiff(day, DeliveryDate, NextDeliveryDate) RawQty,
			Convert(Int, Case When Rate*(DateDiff(day, DeliveryDate, NextDeliveryDate)) < 1.0 Then 0 Else Round(Rate*DateDiff(day, DeliveryDate, NextDeliveryDate), 0) End) SuggestedQty
		From @FilteredAccounts a 
		Join Smart.Daily d on a.SAPAccountNumber = d.SAPAccountNumber
	End
	Else
	Begin
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
			+ 'Smart.pGetSuggestedOrdersForCustomers reads from Smart.Daily1'
		Insert Into @Results 
		Select d.SAPAccountNumber, a.DeliveryDate, 
			DateDiff(day, DeliveryDate, NextDeliveryDate) NumberOfDays, d.SAPMaterialID, Rate, Rate*DateDiff(day, DeliveryDate, NextDeliveryDate) RawQty,
			Convert(Int, Case When Rate*(DateDiff(day, DeliveryDate, NextDeliveryDate)) < 1.0 Then 0 Else Round(Rate*DateDiff(day, DeliveryDate, NextDeliveryDate), 0) End) SuggestedQty
		From @FilteredAccounts a 
		Join Smart.Daily1 d on a.SAPAccountNumber = d.SAPAccountNumber
	End

	Select SAPAccountNumber, DeliveryDate, ItemNumber, SuggestedQty
	From @Results
	Where SuggestedQty > 0
	Order By SAPAccountNumber

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pGetSuggestedOrdersForCustomers created'
Go

Declare @test Smart.tCustomerOrderInput

Insert @test Values(11307896, '2019-02-11', '2019-03-03') --Lows
Insert @test Values(11307893, '2019-02-11', '2019-02-14') --Lows
Insert @test Values(11234400, '2019-02-11', '2019-02-14') --'Walmart, 50'
Insert @test Values(11235319, '2019-02-11', '2019-02-14') --'Walmart, 170'
Insert @test Values(11497602, '2019-02-11', '2019-02-14') --'Target'
Insert @test Values(12663423, '2019-02-11', '2019-03-14') --'Price Chopper Express 009405, 50'
Insert @test Values(12063909, '2019-02-11', '2019-03-14') --'Family Dollar 005570, 50'
Insert @test Values(11233202, '2019-02-11', '2019-03-14') --'Target 001177, 50'


exec Smart.pGetSuggestedOrdersForCustomers @SAPAccounts = @test, @Debug = 1
Go






