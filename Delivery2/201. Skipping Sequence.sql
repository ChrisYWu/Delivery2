Select @@SERVERNAME
Go

Use Merch
Go


Select *
From Setup.MerchGroup mg
Join SAP.Branch b on mg.SAPBranchID = b.SAPBranchID
Where GroupName = 'Division 3'

With Temp As
(
	Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
			Row_Number() Over (Partition By rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek Order By Sequence) NewSequence
	From Planning.RouteStoreWeekday rsw
	Where rsw.MerchGroupID = 73 --<<---- Replace it with users merch groupid
)
Select *
From Temp 
Where Sequence <> NewSequence

Select *
From Planning.RouteStoreWeekday
Where MerchGroupID = 73

--Select *
--From Planning.route
--Where RouteID = 3911

Update rsw
Set rsw.Sequence = t.NewSequence,
	LastModified = SysUTCDatetime(),
	LastModifiedBy = 'WUXYX001'  --<<---- Replace it with users gsn 
From Planning.RouteStoreWeekday rsw Join (
	Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
			Row_Number() Over (Partition By rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek Order By Sequence) NewSequence
	From Planning.RouteStoreWeekday rsw
	Where rsw.MerchGroupID = 73 --<<---- Replace it with users merch groupid
) t
On rsw.RouteID = t.RouteID And rsw.MerchGroupID = t.MerchGroupID  And rsw.DayOfWeek = t.DayOfWeek And rsw.SAPAccountNumber = t.SAPAccountNumber And rsw.Sequence = t.Sequence


Update pd
Set pd.Sequence = t.NewSequence,
LastModified = SysUTCDateTime(),
LastModifiedBy = 'WUXYX001'  --<<---- Replace it with users gsn 
--Select *
From Planning.PreDispatch pd Join (
	Select pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
		Row_Number() Over (Partition By pd.DispatchDate, pd.MerchGroupID, pd.RouteID Order By Sequence) NewSequence
	From Planning.PreDispatch pd
	Where pd.MerchGroupID = 73 --<<---- Replace it with users merch groupid
	And RouteID <> -1
	And DispatchDate >= Convert(Date, GetDate())
) t
on pd.RouteID = t.RouteID And pd.DispatchDate = t.DispatchDate And pd.GSN = t.GSN and pd.Sequence = t.Sequence And pd.MerchGroupID = t.MerchGroupID

With Schedule As
(
	Select pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
		Row_Number() Over (Partition By pd.DispatchDate, pd.MerchGroupID, pd.RouteID Order By Sequence) NewSequence
	From Planning.PreDispatch pd
	Where pd.MerchGroupID = 73 --<<---- Replace it with users merch groupid
	And RouteID <> -1
	And DispatchDate >= Convert(Date, GetDate())
)
Select *
From Schedule
Where Sequence <> NewSequence

	--Select pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
	--	Row_Number() Over (Partition By pd.DispatchDate, pd.MerchGroupID, pd.RouteID Order By Sequence) NewSequence
	--From Planning.PreDispatch pd
	--Where pd.MerchGroupID = 73 --<<---- Replace it with users merch groupid
	--And RouteID <> -1
	--And DispatchDate >= Convert(Date, GetDate())


	--Select *
	--From Planning.Route
	--Where RouteName = 'San Diego - 302' --652

	--Select pd.*, a.AccountName, pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
	--Row_Number() Over (Partition By pd.DispatchDate, pd.MerchGroupID, pd.RouteID Order By Sequence) NewSequence
	--From Planning.PreDispatch pd
	--Join SAP.Account a on pd.SAPAccountNumber = a.SAPAccountNumber
	--Where pd.MerchGroupID = 73 --<<---- Replace it with users merch groupid
	--And RouteID = 652
	--And DispatchDate = DateAdd(Day, 1, Convert(Date, GetDate()))
