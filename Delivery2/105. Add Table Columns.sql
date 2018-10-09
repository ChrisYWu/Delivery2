use merch
Go

Select top 1 *
From Operation.MerchStopcheckIn
Go

Alter Table Operation.MerchStopcheckIn
Add CheckInDistanceInMiles Decimal(11,1)
Go

Print 'CheckInDistanceInMiles column added to table Operation.MerchStopcheckIn'
Go

Update chkIn
Set CheckInDistanceInMiles = dbo.udfDistanceInMiles(acc.Latitude, acc.Longitude, chkIn.CheckInLatitude, chkIn.CheckInLongitude)
From Operation.MerchStopcheckIn chkIn
Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
Go

Print 'Operation.MerchStopcheckIn updated'
Go

Alter Table Operation.MerchStopcheckOut
Add CheckOutDistanceInMiles Decimal(11,1)
Go

Print 'CheckOutDistanceInMiles column added to table Operation.MerchStopcheckOut'
Go

Update o
Set CheckOutDistanceInMiles = dbo.udfDistanceInMiles(acc.Latitude, acc.Longitude, o.CheckOutLatitude, o.CheckOutLongitude)
From Operation.MerchStopcheckIn chkIn
Join Operation.merchStopcheckOut o on chkIn.MerchStopID = o.MerchStopID
Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
Go

Print 'Operation.merchStopcheckOut updated'
Go
