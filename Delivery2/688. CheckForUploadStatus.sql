Use Merch
Go

Select convert(Datetime2(1), l.RequestTime) ActivityTime, 
	Case When e.LogID is null then 'Successful'
	Else 'Error'
	End Status,
	convert(Datetime2(1), e.ServerInserttime) ExceptionTime, l.LogID ActivityLogID, e.LogID ExceptionLogID, l.WebEndPoint, l.StoredProc, l.GetParemeters, l.PostJson, e.GSN, e.Exception, e.ComputerName, e.UserAgent, e.ModifiedDate, l.CorrelationID
From Mesh.MyDayActivityLog l
Full outer join Setup.WebAPILog e on l.CorrelationID = e.CorrelationID
Where (l.CorrelationID is not null or e.CorrelationID is not null)
--And e.LogID is Null
Order by coalesce(l.RequestTime, e.ServerInsertTime) Desc

--Select top 20 *
--From Setup.WebAPILog
--Order By LogID desc

--Select top 20 *
--From Mesh.MyDayActivityLog
----where CorrelationID = '46fc6915-1469-4186-b923-d67bc647'
--Order By LogID desc

--Select BranchName, b.SAPBranchID, mg.GroupName, p.GSN, p.FirstName, p.LastName
--From Setup.Merchandiser m
--Join Setup.Person p on m.GSN = p.GSN
--Join Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
--Join SAP.Branch b on b.SAPBranchID = mg.SAPBranchID
--Where b.BranchName <> 'Elmsford'
--Order by BranchName, b.SAPBranchID, mg.GroupName, p.GSN, p.FirstName, p.LastName


--Select *
--from SAP.Branch
--Where BranchName like '%m%'
--order by BranchName


