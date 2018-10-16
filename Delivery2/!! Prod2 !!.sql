Use Merch
Go

Select @@SERVERNAME
Go

Select DB_Name()
Go

--EXEC Export.pGetStoreServiceReport '15', '2018-10-11', '2018-10-16'
--Go

Declare @Sig Table
(
	MerchStopID bigint,
	ManagerName Varchar(50),
	ManagerSignature varchar(50)
)

Insert Into @Sig
Select MerchStopID,
REPLACE(ltrim(sig.ManagerName), ',',' ') as 'ManagerName', 		
CAST(sig.ImageBlobID as VARCHAR(50)) as 'ManagerSignature'	
From Operation.MerchStopCheckIn chkIn
Left join Operation.MerchStoreSignature sig on chkIn.GSN = sig.GSN  and sig.SAPAccountNumber = chkIn.SAPAccountNumber and sig.DispatchDate = chkIn.DispatchDate
Where chkIn.MerchGroupID = 15
	AND chkIn.DispatchDate between '2018-10-08' and '2018-10-16' 

Select  branch.BranchName as Branch,
	ltrim(p.FirstName) + ' ' + ltrim(p.LastName) as Merchandiser,
	convert(varchar, chkOut.ClientCheckOutTime, 101) as 'Date',
	chain.LocalChainName as 'Chain',
	acc.AccountName as 'StoreName', 
	convert(nvarchar, CAST(chkIn.ClientCheckInTime as time), 100)  + ' ' + chkIn.ClientCheckInTimeZone as 'StartTime',	
	convert(nvarchar, CAST(chkOut.ClientCheckOutTime as time), 100)  + ' ' + chkOut.ClientCheckOutTimeZone as 'EndTime',
	chkIn.ClientCheckInTime,
	chkOut.ClientCheckOutTime,	 
	convert(varchar(10),DateDiff(minute, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime) ) as 'TimeinStoreMins',
	convert(varchar(5),DateDiff(s, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime)/3600)+' hrs '+convert(varchar(5),DateDiff(s, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime)%3600/60) + ' mins' as 'TimeinStoreHours',
	sig.ManagerName, 		
	sig.ManagerSignature,		
	chkOut.CasesHandeled as 'CasesWorked', 
	chkOut.CasesInBackroom as 'CasesInBackstock',		
	STUFF((
			Select ';' + CAST(pic.PictureBlobID as VARCHAR(50)) from Operation.MerchStorePicture pic 
			where pic.DispatchDate = chkIn.DispatchDate and pic.GSN = chkIn.GSN and pic.SAPAccountNumber = chkIn.SAPAccountNumber and pic.DispatchDate = chkIn.DispatchDate
		FOR XML PATH('')
				,TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as 'StorePics',
	STUFF((
			Select '; ' + pic.Caption from Operation.MerchStorePicture pic 
			where pic.DispatchDate = chkIn.DispatchDate and pic.GSN = chkIn.GSN and pic.SAPAccountNumber = chkIn.SAPAccountNumber and pic.DispatchDate = chkIn.DispatchDate
		FOR XML PATH('')
				,TYPE
			).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as 'PicsLocation',
	Replace(Replace(Replace(chkOut.Comments, ',', ';'), Char(10), ''), Char(13), '') Comments,
	chkIn.CheckInDistanceInMiles CKINDistance,
	chkOut.CheckOutDistanceInMiles CKOUTDistance,
	'"' + convert(varchar(40),acc.Latitude)  + ',' + convert(varchar(40),acc.Longitude) + '"' as 'StoreLocation',
	'"' + convert(varchar(40),chkIn.CheckInLatitude)  + ',' + convert(varchar(40),chkIn.CheckInLongitude) + '"' as 'CKINLocation',
	'"' + convert(varchar(40),chkOut.CheckOutLatitude)  + ',' + convert(varchar(40),chkOut.CheckOutLongitude) + '"' as 'CKOUTLocation',
	acc.Address, acc.City,acc.PostalCode, acc.State
from Operation.MerchStopCheckIn chkIn 
left Join Operation.MerchStopCheckOut chkOut  on chkIn.MerchStopID = chkOut.MerchStopID
left Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
left join SAP.LocalChain chain on acc.LocalChainID = chain.LocalChainID
join @Sig sig on chkIn.MerchStopID = sig.MerchStopID 
left join Setup.MerchGroup grp on chkIn.MerchGroupID = grp.MerchGroupID
inner join SAP.Branch branch on branch.SAPBranchID = grp.SAPBranchID
left join Setup.Person p on p.GSN = chkIn.GSN
Where chkIn.MerchGroupID = 15
	AND chkIn.DispatchDate between '2018-10-10' and '2018-10-16' 