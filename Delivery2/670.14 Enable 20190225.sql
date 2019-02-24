Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Alter Proc dbo.pEnableBranchesForMesh
As
	Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
	Select 6 FeatureID, SAPBranchID BranchID, 1 IsActive
	From SAP.Branch
	Where SAPBranchID in (
	1002,1003,1004,1005,1006,
	1008,1010,1012,1015,1016,
	1020,1021,1022,1023,1024,
	1025,1027,1030,1032,1034,
	1036,1037,1056,1057,1061,
	1062,1066,1068,1069,
	1070,1071,1073,1074,1075,
	1076,1077,1078,1088,1090,
	1092,1093,1094,1095,1096,
	1097,1099,1100,1101,1102,
	1106,1107,1110,1113,1173,
	1187,1192,1193
	)
	And SAPBranchID <> 'TJW1'
	And SAPBranchID Not In (Select BranchID From Shared.Feature_Authorization Where FeatureID = 6)

	Declare @V Varchar(8000)
	Set @V = '' 

	Select @V = @V + Convert(Varchar(10), BranchID) + ','
	From Shared.Feature_Authorization
	Where FeatureID = 6
	Order By BranchID

	Select SUBSTRING(@V, 1, Len(@V) - 1) ConfigValue
	-- 1103,1104,1108,1109,1113,1114,1115,1116,1117,1120,1138,1178,1184 Before changes
	-- 1103,1104,1108,1109,1113,1114,1115,1116,1117,1120,1138,1178,1184 SetupValue

	Update Merch.Setup.Config
	Set Value = SUBSTRING(@V, 1, Len(@V) - 1)
	Where ConfigID = 4
Go

exec dbo.pEnableBranchesForMesh
Go

Select Count(*) Cnt 
From Shared.Feature_Authorization
Where FeatureID = 6

Select *
From Merch.Setup.Config
Go

Select *
From Portal_Data.Shared.Feature_Authorization
Where featureid = 6
