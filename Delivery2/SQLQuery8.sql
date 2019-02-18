use Merch
Go

With Cte As
(
	Select DispatchDate, RouteID, GSN
	From Planning.PreDispatch
	Where DispatchDate <= GetDate()
	Group By DispatchDate, RouteID, GSN
)

Select c.DispatchDate, br.SAPBranchID, br.BranchName, mg.MerchGroupID, mg.GroupName, r.RouteID, r.RouteName, c.GSN
From CTE c
Join
(
	Select DispatchDate, GSN, Count(*) Cnt
	From CTE a
	Group By DispatchDate, GSN
	Having Count(*) > 1
) b on c.DispatchDate = b.DispatchDate and c.GSN = b.GSN
Join Planning.Route r on c.RouteID = r.RouteID
Join Setup.MerchGroup mg on mg.MerchGroupID = r.MerchGroupID
Join SAP.Branch br on mg.SAPBranchID = br.SAPBranchID
Order By c.DispatchDate Desc, c.GSN, c.RouteID
