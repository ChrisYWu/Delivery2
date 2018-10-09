use Merch
Go

  Update [Mesh].[DeliveryRoute]
  Set ActualStartTime = null,
  ActualCompleteTime = null,
  ActualStartFirstName = null,
  ActualStartGSN = null,
  ActualStartLastName = null, 
  ActualStartPhoneNumber = null,
  ActualStartLongitude = null,
  ActualStartLatitude = null
  Where DeliveryDateUTC = convert(Date, GetDate())

  Delete
  From Mesh.DeliveryStop
  Where DeliveryDateUTC = convert(Date, GetDate())

  Delete 
  From [Mesh].[Resequence]
  Where DeliveryDateUTC = convert(Date, GetDate())


