USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'p0DriverUpdate')
Begin
	Drop Proc Notify.p0DriverUpdate
	Print '* Notify.p0DriverUpdate'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec Notify.p0DriverUpdate
*/

Create Proc Notify.p0DriverUpdate
AS
Begin
	Declare @SetTime DateTime
	Declare @MaxTime DateTime

	Select @SetTime = Convert(DateTime, Value)
	From Setup.Config
	Where [Key] = '0LastUpdateTimeFromDriver'

	Select @MaxTime = Max(LocalUpdateTime)
	From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop
	Where DeliveryDateUTC = Convert(Date, GetUTCDate())

	Select @MaxTime MaxTime, @SetTime SetTime

	If (@MaxTime > @SetTime)
	Begin
		Update Setup.Config
		Set Value = Convert(varchar(200), @MaxTime, 21)
		Where [Key] = '0LastUpdateTimeFromDriver'

		Declare @Updates Table
		(
			DeliveryDateUTC Date,
			SAPAccountNumber int,
			DepartureTime DateTime2(0),
			IsEstimated bit,
			DNS Bit
		)
		Insert @Updates 
		Select DeliveryDateUTC, SAPAccountNumber,
		Case When DNS = 1 Then '2049-12-31' Else  
			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
			DateAdd(second, ds.ServiceTime, ds.PlannedArrival)) End DepartureTime, 
		Case When Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, ds.PlannedArrival) Is Null Then 0 When ds.CheckOutTime is null Then 1 Else 0 End IsEstimated 
		, DNS
		From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds
		Where DeliveryDateUTC = Convert(Date, GetUTCDate())
		And SAPAccountNumber is not null
		And Sequence > 0
		And StopType = 'STP'
		And LocalUpdateTime > @SetTime

		Select sm.DeliveryDateUTC, sm.SAPAccountNumber, d.DepartureTime, d.IsEstimated, d.DNS, GetDate()
		From [Notify].[StoreDeliveryMechandiser] sm
		Join @Updates d on sm.DeliveryDateUTC = d.DeliveryDateUTC And d.SAPAccountNumber = sm.SAPAccountNumber

		Insert Into Notify.StoreDeliveryTimeTrail
           (DeliveryDateUTC
           ,SAPAccountNumber
           ,DepartureTime
           ,IsEstimated
           ,DNS
           ,ReportTimeLocal)
		Select sm.DeliveryDateUTC, sm.SAPAccountNumber, d.DepartureTime, d.IsEstimated, d.DNS, GetDate()
		From [Notify].[StoreDeliveryMechandiser] sm
		Join @Updates d on sm.DeliveryDateUTC = d.DeliveryDateUTC And d.SAPAccountNumber = sm.SAPAccountNumber
		Where sm.DepartureTime <> d.DepartureTime

		Update sm
		Set DepartureTime = d.DepartureTime,
		IsEstimated = d.IsEstimated,
		DNS = d.DNS
		From Notify.StoreDeliveryMechandiser sm
		Join @Updates d on sm.DeliveryDateUTC = d.DeliveryDateUTC And d.SAPAccountNumber = sm.SAPAccountNumber
		Where sm.DepartureTime <> d.DepartureTime
	End
End

Go

Print 'Notify.p0DriverUpdate created'
Go

--exec Notify.p0DriverUpdate
--Go
