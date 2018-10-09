Use Merch
Go

Select *
From SaP.Branch
Where BranchName = 'Waco'

Select *
From Setup.Person

Select *
From Setup.Merchandiser m
Join Setup.MerchGroup g on m.MerchGroupID = g.MerchGroupID
Where g.SAPBranchID = 1120
And Phone <> ''
Order By GSN

Select *
From Setup.Merchandiser m
Where GSN in (
'PATBX022'
,'NAJNX001'
,'RAMJX055'
,'RADRJ001'
,'JONDX063'
)



--Select *
--From Portal_Data.Person.UserProfile
--Where GSN = 'THOKK002'
--Go

--Select ab.AbsoluteURL, a.LastModified, a.*
--From Operation.DisplayBuild a
--Join Operation.AzureBlobStorage ab on a.InstructionImageBlobID = ab.BlobID
--Where a.LastModifiedBy = 'THOKK002'
--Order By a.LastModified Desc


--Select ab.AbsoluteURL, ClientTime, a.LastModified, a.*
--From Operation.DisplayBuildExecution a
--Join Operation.AzureBlobStorage ab on a.ImageBlobID = ab.BlobID
--Where GSN = 'IVEJX001'
--Order By a.LastModified Desc

