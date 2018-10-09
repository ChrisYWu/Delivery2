USE [Merch]
GO
/****** Object:  StoredProcedure [Operation].[pGetMerchandisingDetails]    Script Date: 5/22/2018 4:17:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Exec Operation.pGetMerchandisingDetails '2017-12-11', '11297784, 12284717, 11297027'
Exec Operation.pGetMerchandisingDetails '2017-04-27', '11276243,11287373,11279661,11276015'
Exec Operation.pGetMerchandisingDetails '2018-01-10', '11315063'
Exec Operation.pGetMerchandisingDetails '2018-01-11', '11318546'

*/

ALTER Proc Operation.pGetMerchandisingDetails
(
	@OperationDate Datetime,
	@SAPAccountNumber varchar(max)
)
AS
Begin
	Set NoCount On;

	Select 
	--GSNStoreSequence, 
	Convert(int, Row_Number() Over (Partition By SAPAccountNumber Order By IsNull(CheckInTime, '2199-12-31'))) SameStoreCheckInSequence, 
	merc.GSN, 
	SAPAccountNumber, 
	p.FirstName, 
	p.LastName, 
	m.Phone, 
	CheckInTime, 
	CheckOutTime
	From 
	(
		Select COALESCE(actual.GSNStoreSequence, pln.GSNStoreSequence) GSNStoreSequence, 
		COALESCE(actual.GSN, pln.GSN) GSN,
		COALESCE(actual.SAPAccountNumber, pln.SAPAccountNumber) SAPAccountNumber, 
		actual.CheckInTime, actual.CheckOutTime
		From 
		(
			Select Row_Number() Over (Partition By GSN, SAPAccountNumber Order By Sequence) GSNStoreSequence, GSN, SAPAccountNumber
			From Planning.Dispatch
			Where SAPAccountNumber in (Select LTRIM(rtrim(value)) From Setup.UDFSplit(@SAPAccountNumber, ','))
			And InvalidatedBatchID is null
			And DispatchDate = @OperationDate
		) pln
		Full Outer Join 
		(
			Select Row_Number() Over (Partition By inn.GSN, SAPAccountNumber Order By ClientCheckInTime) GSNStoreSequence, inn.GSN, 
			SAPAccountNumber,
			Convert(DateTime2(0), DateAdd(hour, 1*IsNull(tc.OffsetToUTC, 0), inn.ClientCheckInTime)) CheckInTime, 
			Convert(DateTime2(0), DateAdd(hour, 1*IsNull(tco.OffsetToUTC, 0), ot.ClientCheckOutTime)) CheckOutTime
			From Operation.MerchStopCheckIn inn
			Left Join Setup.TimeConversion tc on inn.ClientCheckInTimeZone = tc.TimeZone
			Left Join Operation.MerchStopCheckOut ot on ot.MerchStopID = inn.MerchStopID
			Left Join Setup.TimeConversion tco on ot.ClientCheckOutTimeZone = tco.TimeZone
			Where DispatchDate = @OperationDate
			And SAPAccountNumber in (Select LTRIM(rtrim(value)) From Setup.UDFSplit(@SAPAccountNumber, ','))
		) actual on pln.GSNStoreSequence = actual.GSNStoreSequence And pln.GSN = actual.GSN And pln.SAPAccountNumber = actual.SAPAccountNumber
	) merc
	Left Join Setup.Person p on merc.GSN = p.GSN
	Left Join Setup.Merchandiser m on p.GSN = m.GSN
	Order By SAPAccountNumber
End
