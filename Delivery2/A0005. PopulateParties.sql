

Merge [Notify].[Party] as tar
Using (
Select m.GSN, p.Firstname, p.LastName, m.Phone, Null Email, 'Merchandiser' Role, (Case When SAPBranchID = 1120 Then -7 Else -5 End) TimeZoneOffSet, SAPBranchID
From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
Join DPSGSHAREDCLSTR.Merch.Setup.Person p on m.GSN = p.GSN 
Where SAPBranchID in (1120, 1138)
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






