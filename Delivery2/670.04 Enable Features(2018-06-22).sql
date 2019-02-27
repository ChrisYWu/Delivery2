Use Portal_Data
Go

Select *
From SAP.Branch
Where SAPBranchID = '1120'
Go

Select *
From Shared.Feature_Applications

Select *
From Shared.Feature_Master 

Set IDENTITY_INSERT Shared.Feature_Applications On
Insert Into Shared.Feature_Applications(ID, ApplicationID, ApplicationName, IsActive)
Values(2, 2, 'DRIVERMYDAY ', 1)
Set IDENTITY_INSERT Shared.Feature_Applications Off
Go

Set IDENTITY_INSERT Shared.Feature_Master On
Insert Into Shared.Feature_Master(FeatureID, FeatureName, ApplicationID, IsActive, IsCustomized)
Values(6, 'ESTIMATES', 2, 1, 1)
Set IDENTITY_INSERT Shared.Feature_Master Off
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1120, 1)
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Go

Use Merch
Go

Set IDENTITY_INSERT Setup.Config On
INSERT Setup.Config (ConfigID, [Key], Value, [Description], ModifiedDate, SendToMyday) VALUES (4, N'MeshEnabledBranches', N'1120', N'Mesh enabled branches in SAP Branch ID', CAST(N'2018-05-01 00:00:00.000' AS DateTime), 1)
GO
INSERT Setup.Config (ConfigID, [Key], Value, [Description], ModifiedDate, SendToMyday) VALUES (9, N'MeshMyDayLog', N'1', N'Enable log for MyDay activities for Mesh Delivery', CAST(N'2018-05-01 00:00:00.000' AS DateTime), 1)
GO
Set IDENTITY_INSERT Setup.Config Off
Go

Update Setup.Config
Set Value = '1120'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go

Print '-- $$$$ Branch enabled [Waco] $$$$--'
Go

Use Portal_Data
Go


Delete Shared.Feature_Authorization
Where FeatureID = 6

Use Merch
Go

Update Setup.Config
Set Value = ''
Where ConfigID = 4
Go

--select *
--from setup.userlocation
--where gsn = 'ACHMX001'
--order by sapbranchID

--Select *
--From ETL.DataLoadingLog

--Select Distinct DeliveryDATeUTC
--From Mesh.CustomerOrder
--Order By DeliveryDATeUTC Desc

--Select Distinct DeliveryDATeUTC
--From Mesh.OrderItem
--Order By DeliveryDATeUTC Desc
