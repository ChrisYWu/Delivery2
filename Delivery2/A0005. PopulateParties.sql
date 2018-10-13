/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [PartyID]
      ,[Phone]
      ,[Email]
      ,[Role]
      ,[TimeZoneOffset]
  FROM [Merch].[Notify].[Party]

Merge [Merch].[Notify].[Party] as tar
Using (
Select m.GSN, p.Firstname, p.LastName, m.Phone, Null Email, 'Merchandiser' Role, -5 TimeZoneOffSet
From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
Join DPSGSHAREDCLSTR.Merch.Setup.Person p on m.GSN = p.GSN 
Where SAPBranchID = 1178
And M.Phone <> '') Input 
On Tar.PartyID = input.GSN
When Matched
Then Update
SEt Tar.Phone = input.Phone, Tar.TimeZoneOffSet = input.TimeZoneOffset
When Not Matched
Then Insert([PartyID]
      ,[Phone]
      ,[Role]
      ,[TimeZoneOffset])
	  Values(input.GSN, input.Phone, input.Role, input.TimeZoneOffset);
Go

