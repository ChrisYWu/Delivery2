Use Merch
Go
Select Top 100 *
From Setup.WebAPILog
Order By LogID desc

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select b.SAPBranchID, b.BranchName, m.MerchGroupID, mg.GroupName, m.GSN, m.TimeZoneOffSet, m.LastModified
From Setup.Merchandiser m
Join Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
Join SAP.Branch b on mg.SAPBranchID = b.SAPBranchID
Where GSN = 'WUXYX001'

Select top 100 *
From Operation.StoreDelivery s
Join SAP.Account a on s.SAPAccountNumber = a.SAPAccountNumber
Where DeliveryDate = '2019-01-30'
And a.BranchID = 161

Select *
From Setup.Config

Select *
From Mesh.DeliveryRoute
Where Left(RouteID,4) in (1103,1104,1120,1138,1178,1100)
And DeliveryDateUTC = '2019-01-30'
Order By RouteID

Update Setup.Config
Set Value = '1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1018,1021,1022,1023,1024,1025,1026,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1040,1041,1042,1043,1044,1045,1046,1047,1048,1049,1050,1051,1052,1053,1054,1055,1056,1057,1058,1059,1060,1061,1062,1064,1065,1066,1068,1069,1070,1071,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1091,1092,1093,1094,1095,1096,1097,1098,1099,1100,1101,1102,1103,1104,1105,1106,1107,1108,1109,1110,1111,1112,1113,1114,1116,1117,1118,1119,1120,1121,1122,1123,1124,1125,1126,1127,1128,1129,1130,1131,1132,1133,1134,1135,1136,1137,1138,1139,1140,1141,1142,1144,1145,1146,1147,1158,1159,1160,1161,1162,1163,1164,1165,1166,1167,1169,1171,1172,1173,1175,1177,1178,1179,1180,1181,1182,1183,1184,1185,1186,1187,1189,1190,1191,1192,1193,1194,1195,1196,1197,1198'
Where [Key] = 'MeshEnabledBranches'

Select *
From SAP.Branch
Where SAPBranchID = '1115'

Select *
From Setup.Merchandiser
Where GSN = 'WUXYX001'

Select Top 100 *
From Mesh.MyDayActivityLog
Order By LogID desc

Select *
From Mesh.DeliveryStop
Where DeliveryDateUTC = '2019-01-24'

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = '2019-01-24'

Update Setup.Merchandiser
Set TimeZoneOffSet = 0, MerchGroupID = 38
Where GSN = 'WUXYX001'

Select *
From Setup.MerchGroup
Where MerchGroupID = 39

Select b.*, m.*
From SEtup.MerchGroup m
Join SAP.Branch b on m.SAPBranchID = b.SAPBranchID
Where b.SAPBranchID = '1115'

Select *
From Setup.Config

Select RouteID, Count(*)
From Mesh.PlannedStop
Where DeliveryDateUTC = Convert(Date, GetDate())
And SAPAccountNumber in (
Select SAPAccountNumber
From Setup.Store
Where MerchGroupID = 174
)
Group By RouteID

Select *
From APNSMerch.DeliveryInfo
Where DeliveryDateUTC = Convert(Date, GetDate())
And MerchandiserGSN = 'WUXYX001'

Select *
From mesh.DeliveryStop
Where DeliveryDateUTC = Convert(Date, GetDate())
And RouteID = 110302824


Select *
From APNS.NotificationQueue

exec  APNS.pGetMessagesForNotification @LockerID='00', @Debug=1


Select *
From SEtup.Merchandiser
Where GSN = 'WUXYX001'


Select *
From mesh.PlannedStop
Where DeliveryDateUTC = '2019-01-24'
And RouteID like '1103%'

Select *
From mesh.DeliveryStop
Where DeliveryDateUTC = '2019-01-24'

Select *
From APNS.AppUsertoken


