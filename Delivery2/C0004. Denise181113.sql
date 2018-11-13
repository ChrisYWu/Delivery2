Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select mg.GroupName, r.*
From Planning.Route r
Join Setup.MerchGroup mg on r.MerchGroupID = mg.MerchGroupID
Where RouteName = 'Brighton'

Declare @RouteID Int
Set @RouteID = 1796

exec Planning.pGetPreDispatch @MerchGroupID=174, @DispatchDate = '2018-11-13', @GSN = 'System', @TimeZoneOffSetToUTC = 6, @Reset = 0, @Debug = 1
