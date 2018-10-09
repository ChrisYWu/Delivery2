/*
1. exec ETL.pLoadDeliveryPlanFromRN;
2. exec ETL.pMergeDeliveryPlan;
3. exec ETL.pProcessPlannedDelivery;


*/

use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('A_________________'))
Begin
	Drop Proc A_________________
	Print '* A_________________'
End
Go

/*
TESTING QUERY

exec A_________________

*/

Create Proc A_________________
As
	Set NOCOUNT ON;  

Go

--exec A_________________

Print 'Creating A_________________'
Go

