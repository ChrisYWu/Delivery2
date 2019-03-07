Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go


/*
WALMART SC 005144	Walmart - Predictive 	Robert Robles	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 003112	Walmart - Smart 	Joshua Rodriguez	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 005145	Walmart - Predictive 	Greg Smith 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 001347	Walmart - Control	Anthony Amadiez	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 001313	Walmart - Predictive 	Laura Engestan	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 003279	Walmart - Smart 	Adrain Rodriguez	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 003106	Walmart - Control	Rudy Hernandez 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 000999	Walmart - Control	Elias Mosegur	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 002239	Walmart - Control	Roland Jimenez 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 003058	Walmart - Smart 	Joe Morin 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 002864	Walmart - Control	Andrew Salazar 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 002599	Walmart - Predictive 	Jose Aguilar 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 004131	Walmart - Predictive 	Isaac De La Fuente 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 004162	Walmart - Smart 	Juan Limon	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19
WALMART SC 002404	Walmart - Smart 	Melvin Pagie 	1/28/19 - 2/1/19  and 2/28/19 - 3/1/19


*/

Select a.SAPAccountNumber, StoreName, SalesPerson PersonGivenByKevinInHisEmail, DispatchDate Date, msp.GSN, p.FirstName + ' ' + p.LastName Merchandiser, Caption, AbsoluteURL ImageUrl
From BSCCAP108.Portal_Data.dbo.ks20190307 ks
Join SAP.Account a on ks.StoreName = a.AccountName
Join Operation.MerchStorePicture msp on msp.SAPAccountNumber = a.SAPAccountNumber
Join Operation.AzureBlobStorage ab on msp.PictureBlobID = ab.BlobID
Join Setup.Person p on p.GSN = msp.GSN
Where (DispatchDate Between '2019-01-28' And '2019-02-01'
Or DispatchDate Between '2019-02-28' And '2019-03-01')
And Caption like 'Back%'
Order By StoreName, DispatchDate


