USE [Merch]
GO
/****** Object:  StoredProcedure [Operation].[pGetMerchStoreDelivery]    Script Date: 1/8/2019 3:27:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*/

Select Distinct SAPAccountNumber
From Operation.StoreDelivery
Where DeliveryDate = '2019-01-08'

Update Setup.Config
Set Value = '1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1018,1021,1022,1023,1024,1025,1026,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,1046,1047,1048,1049,1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1064,1065,1066,1068,1069,1070,1071,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1091,1092,1093,1094,1095,1096,1097,1098,1099,1100,1101,1102,1103,1104,1105,1106,1107,1108,1109,1110,1111,1112,1113,1114,1115,1116,1117,1118,1119,1120,1121,1122,1123,1124,1125,1126,1127,1128,1129,1130,1131,1132,1133,1134,1135,1136,1137,1138,1139,1140,1141,1142,1144,1145,1146,1147,1158,1159,1160,1161,1162,1163,1164,1165,1166,1167,1169,1171,1172,1173,1175,1177,1178,1179,1180,1181,1182,1183,1184,1185,1186,1187,1189,1190,1191,1192,1193,1194,1195,1196,1197,1198'
Where [Key] = 'MeshEnabledBranches'

Select Distinct B.SAPBranchID
From SAP.Account a
Join SAP.Branch b on a.BranchID = b.BranchID
Where SAPAccountNumber in (11186471,11186503,11186516,11186517,11186518,11186519)


exec Operation.pGetMerchStoreDelivery @DeliveryDate= '2019-01-08', 
	@SAPAccountNumber='11186471,11186503,11186516,11186517,11186518,11186519',
	@IsDetailNeeded=0
	, @Debug=1
/*
http://localhost/DPSG.Portal.Merchandiser.WebAPI/api/Merch/GetMerchStoreDelivery?DeliveryDate=2019-01-08&SAPAccountNumber=11186471,11186503,11186516,11186517,11186518,11186519&IsDetailNeeded=false
*/

use Merch
Go

Select * From APNSMerch.DeliveryInfo

Select Top 10 *
From Setup.WebAPILog
Order By LogID Desc

	Select m.GSN, p.Firstname, p.LastName, m.Phone, Null Email, 'Merchandiser' Role, 
		(Case When SAPBranchID = 1120 Then -6 
			  When SAPBranchID = 1178 Then -6
			  When SAPBranchID = 1103 Then -7
			  When SAPBranchID = 1104 Then -7
			  When SAPBranchID = 1138 Then -8 End) TimeZoneOffSet, SAPBranchID
	From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
	Join DPSGSHAREDCLSTR.Merch.Setup.Person p on m.GSN = p.GSN 
	Where SAPBranchID in (1103, 1104, 1120, 1138, 1178)


	Update m set TimeZoneOffSet = blah.TimeZoneOffSet
	From Setup.Merchandiser m
	Join 
	(
		Select m.GSN, p.Firstname, p.LastName, m.Phone, Null Email, 'Merchandiser' Role, 
			(Case When SAPBranchID = 1120 Then -6 
				  When SAPBranchID = 1178 Then -6
				  When SAPBranchID = 1103 Then -7
				  When SAPBranchID = 1104 Then -7
				  When SAPBranchID = 1138 Then -8 End) TimeZoneOffSet, SAPBranchID
		From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
		Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
		Join DPSGSHAREDCLSTR.Merch.Setup.Person p on m.GSN = p.GSN 
		Where SAPBranchID in (1103, 1104, 1120, 1138, 1178)
	) blah on m.GSN = blah.GSN

/*
Insert APNS.AppUserToken
	Select 1, m.GSN, '07fe4f023fe8a573648669f7ab7815189c7d8a2b23f71b3e52c4034bfb3ae12b', SysDateTime() 
	From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
	Join DPSGSHAREDCLSTR.Merch.Setup.Person p on m.GSN = p.GSN 
	Where SAPBranchID in (1103, 1104, 1120, 1138, 1178)
Select *
From APNS.App
*/

Select *
From APNS.AppUserToken
Where GSN = 'WUXYX001'

With Source As
(
	Select Distinct d.DispatchDate, d.SAPAccountNumber,  
			d.GSN, 
			Coalesce(ds.CheckOutTime, ds.estimatedArrivalTime, 
				DateAdd(second, 0, ds.PlannedArrival), 
				DateAdd(second, 0, ps.PlannedArrival)) ArrivalTime, 
			Coalesce(ds.CheckOutTime, ds.estimatedArrivalTime, 
			DateAdd(second, 0, ds.PlannedArrival), 
			DateAdd(second, 0, ps.PlannedArrival)) KnownArrivalTime, 0 DNS,
		Case When ds.CheckOutTime is null Then 1 Else 0 End IsEstimated, m.SAPBranchID 
	From DPSGSHAREDCLSTR.Merch.Planning.Dispatch d
	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup m on d.MerchGroupID = m.MerchGroupID
	Left Join DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds on d.SAPAccountNumber = ds.SAPAccountNumber and ds.DeliveryDateUTC = d.DispatchDate
	Left Join (
		Select DeliveryDateUTC, SAPAccountNumber, Min(PlannedArrival) PlannedArrival, Sum(ServiceTime) ServiceTime
		From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop ps 
		Where DeliveryDateUTC = '2019-01-09'
		Group By DeliveryDateUTC, SAPAccountNumber
	) ps on d.SAPAccountNumber = ps.SAPAccountNumber and ps.DeliveryDateUTC = d.DispatchDate
	Where SAPBranchID in(1103, 1104, 1120, 1138, 1178)
	And DispatchDate = '2019-01-09'
	And (ds.Sequence Is NUll OR ds.Sequence > 0)
	And InvalidatedBatchID is null
)
--Select * From Source
--Select * From APNSMerch.DeliveryInfo

Insert APNSMerch.DeliveryInfo(DeliveryDateUTC, SAPAccountNumber, MerchandiserGSN, ArrivalTime, KnownArrivalTime, IsEstimated, DNS, LastModifiedBy, LastModified)
Select DispatchDate, SAPAccountNumber, GSN, ArrivalTime, KnownArrivalTime, IsEstimated, DNS, 'DriverGSN', SYSDATETIME()
From Source


Select *
From APNSMerch.DeliveryInfo
Where KnownArrivalTime = '2019-01-09 09:40:14'

Update APNSMerch.DeliveryInfo
Set ArrivalTime = '2019-01-09 09:40:14', KnownArrivalTime = '2019-01-09 09:40:14', IsEstimated = 1
Where ArrivalTime is not null

--Update APNSMerch.DeliveryInfo
--Set ArrivalTime = '2019-01-09 08:00:00', KnownArrivalTime = '2019-01-09 09:40:14', IsEstimated = 1
--Where ArrivalTime is null

SET IDENTITY_INSERT Mesh.DeliveryStop ON

Insert Mesh.DeliveryStop 
(DeliveryStopID, PlannedStopID, DeliveryDateUTC, RouteID, Sequence, StopType, SAPAccountNumber, IsAddedByDriver, Quantity, PlannedArrival, ServiceTime, TravelToTime, LastModifiedBy, LastModifiedUTC, LocalUpdateTime) 
Select DeliveryStopID, PlannedStopID, DeliveryDateUTC, RouteID, Sequence, StopType, SAPAccountNumber, IsAddedByDriver, Quantity, PlannedArrival, ServiceTime, TravelToTime, LastModifiedBy, LastModifiedUTC, LocalUpdateTime
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop 
Where DeliveryStopID in (66471,66472,66474, 66470, 66477, 66473, 66475)

SET IDENTITY_INSERT Mesh.DeliveryStop Off

SET IDENTITY_INSERT Mesh.PlannedStop ON

Insert Mesh.PlannedStop(PlannedStopID, [DeliveryRouteID]
           ,[PKEY]
           ,[DeliveryDateUTC]
           ,[RouteID]
           ,[Sequence]
           ,[StopType]
           ,[SAPAccountNumber]
           ,[Quantity]
           ,[PlannedArrival]
           ,[TravelToTime]
           ,[ServiceTime]
           ,[LastModifiedBy]
           ,[LastModifiedUTC]
           ,[LocalSyncTime]
           ,[OrderCountLastUpdatedLocalTime])
Select PlannedStopID, [DeliveryRouteID]
           ,[PKEY]
           ,[DeliveryDateUTC]
           ,[RouteID]
           ,[Sequence]
           ,[StopType]
           ,[SAPAccountNumber]
           ,[Quantity]
           ,[PlannedArrival]
           ,[TravelToTime]
           ,[ServiceTime]
           ,[LastModifiedBy]
           ,[LastModifiedUTC]
           ,[LocalSyncTime]
           ,[OrderCountLastUpdatedLocalTime]
From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop
Where DeliveryDateUTC = '2019-01-09'
SET IDENTITY_INSERT Mesh.PlannedStop Off

SET IDENTITY_INSERT Mesh.DeliveryRoute On
Insert Into Mesh.DeliveryRoute
           (DeliveryRouteID,
		    [PKEY]
           ,[DeliveryDateUTC]
           ,[RouteID]
           ,[TotalQuantity]
           ,[PlannedStartTime]
           ,[SAPBranchID]
           ,[FirstName]
           ,[Lastname]
           ,[PhoneNumber]
           ,[PlannedCompleteTime]
           ,[PlannedTravelTime]
           ,[PlannedServiceTime]
           ,[PlannedBreakTime]
           ,[PlannedPreRouteTime]
           ,[PlannedPostRouteTime]
           ,[ActualStartTime]
           ,[ActualStartGSN]
           ,[ActualStartFirstName]
           ,[ActualStartLastName]
           ,[ActualStartPhoneNumber]
           ,[ActualStartLatitude]
           ,[ActualStartLongitude]
           ,[ActualCompleteTime]
           ,[LastModifiedBy]
           ,[LastModifiedUTC]
           ,[LocalSyncTime]
           ,[OrderCountLastUpdatedLocalTime]
           ,[LastManifestFetched])
Select DeliveryRouteID,
		    [PKEY]
           ,[DeliveryDateUTC]
           ,[RouteID]
           ,[TotalQuantity]
           ,[PlannedStartTime]
           ,[SAPBranchID]
           ,[FirstName]
           ,[Lastname]
           ,[PhoneNumber]
           ,[PlannedCompleteTime]
           ,[PlannedTravelTime]
           ,[PlannedServiceTime]
           ,[PlannedBreakTime]
           ,[PlannedPreRouteTime]
           ,[PlannedPostRouteTime]
           ,[ActualStartTime]
           ,[ActualStartGSN]
           ,[ActualStartFirstName]
           ,[ActualStartLastName]
           ,[ActualStartPhoneNumber]
           ,[ActualStartLatitude]
           ,[ActualStartLongitude]
           ,[ActualCompleteTime]
           ,[LastModifiedBy]
           ,[LastModifiedUTC]
           ,[LocalSyncTime]
           ,[OrderCountLastUpdatedLocalTime]
           ,[LastManifestFetched] From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryRoute
Where DeliveryDateUTC = '2019-01-09'
SET IDENTITY_INSERT Mesh.DeliveryRoute Off

Select *
From APNSMerch.DeliveryInfo
Where DeliveryDateUTC = '2019-01-09'
And SAPAccountNumber in (12006048
,11321447
,11963702
,11326130
,11320992
,11323174)

Select *
From Mesh.DeliveryStop 
Where DeliveryStopID in (66471,66472,66474, 66470, 66477, 66473, 66475)
