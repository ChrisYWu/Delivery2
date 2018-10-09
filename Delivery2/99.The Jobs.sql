--- The job

Use DSDDelivery
Go

Truncate Table Operation.DeliveryPlan;
Truncate Table Operation.Delivery;

exec ETL.pLoadDeliveryPlanFromRN;
exec ETL.pMergeDeliveryPlan;
exec ETL.pProcessPlannedDelivery;
exec ETL.pUploadToAzure

-- (2017-03-14, 492465, 103402651, 642787, 2:Store, 2017-03-14 11:19:29, 11313218)

Select *
From Staging.RNDeliveryPlan
Where RNKey = 492465
And Route_Number = '103402651'
And Stop_ID = '11313218'


