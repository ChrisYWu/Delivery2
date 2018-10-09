Declare @j Nvarchar(max)

Set @j = '{"DeliveryStops":[{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":1,"StopType":"1:BranchStart","StopID":11081101,"PlannedArrivalTime":"2017-03-15T03:30:00","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":900},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":2,"StopType":"2:Store","StopID":11991743,"PlannedArrivalTime":"2017-03-15T04:35:09","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1236},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":3,"StopType":"2:Store","StopID":11308153,"PlannedArrivalTime":"2017-03-15T05:31:20","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":3834},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":4,"StopType":"2:Store","StopID":11308420,"PlannedArrivalTime":"2017-03-15T06:41:12","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":6012},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":5,"StopType":"2:Store","StopID":11308945,"PlannedArrivalTime":"2017-03-15T08:56:36","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1980},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":6,"StopType":"2:Store","StopID":11342667,"PlannedArrivalTime":"2017-03-15T10:05:37","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1224},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":7,"StopType":"2:Store","StopID":12290890,"PlannedArrivalTime":"2017-03-15T10:34:03","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1284},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":8,"StopType":"2:Store","StopID":11309343,"PlannedArrivalTime":"2017-03-15T11:04:21","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1032},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":9,"StopType":"2:Store","StopID":11478041,"PlannedArrivalTime":"2017-03-15T11:31:33","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1212},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":10,"StopType":"2:Store","StopID":12309444,"PlannedArrivalTime":"2017-03-15T12:09:19","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1644},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":11,"StopType":"2:Store","StopID":12237993,"PlannedArrivalTime":"2017-03-15T12:45:27","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1260},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":12,"StopType":"2:Store","StopID":12346393,"PlannedArrivalTime":"2017-03-15T13:12:19","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1212},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":13,"StopType":"2:Store","StopID":11968480,"PlannedArrivalTime":"2017-03-15T13:41:31","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1500},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":14,"StopType":"2:Store","StopID":11964621,"PlannedArrivalTime":"2017-03-15T14:18:40","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1104},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":15,"StopType":"2:Store","StopID":11996317,"PlannedArrivalTime":"2017-03-15T14:49:18","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1644},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":16,"StopType":"2:Store","StopID":11361868,"PlannedArrivalTime":"2017-03-15T15:26:28","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1236},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":17,"StopType":"2:Store","StopID":12278495,"PlannedArrivalTime":"2017-03-15T16:01:11","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":1380},{"DeliveryDate":"2017-03-15","RouteNumber":"110802221","DriverID":"646700","StopSequence":18,"StopType":"3:BranchReturn","StopID":11081101,"PlannedArrivalTime":"2017-03-15T17:14:23","ActualArrivalTime":null,"TimeZone":"CST","PlannedServiceTimeInSec":900}],"ErrorMessage":"","ResponseStatus":1,"StackTrace":"","Information":null}'

Select IsJson(@j)

--SELECT SalesOrderJsonData.*  
--FROM OPENJSON (@j, '$.DeliveryStops')  
--           WITH (  
--              StopID			varchar(200)	N'$.StopID',   
--              DeliveryDate		date			N'$.DeliveryDate',  
--              StopType			varchar(200)	N'$.StopType',   
--              DriverID			int				N'$.DriverID'  
--           )  
--  AS SalesOrderJsonData;  

Select *
FROM	
	OPENJSON (@j, '$.DeliveryStops')  
	WITH (  
		StopID			varchar(200)	N'$.StopID',   
		DeliveryDate	date			N'$.DeliveryDate',  
		StopType		varchar(200)	N'$.StopType',   
		DriverID		int				N'$.DriverID'  
	) Stops

Select Json_Value(@j, '$.ResponseStatus') ResponseStatus

		  
  --AS SalesOrderJsonData;  

