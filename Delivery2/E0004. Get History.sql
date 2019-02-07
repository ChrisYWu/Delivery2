use Portal_Data
Go

If Not Exists (Select * From sys.schemas Where Name = 'Smart')
Begin
	exec('Create Schema Smart')
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'SaleHistory' and s.name = 'Smart')
Begin
	Drop Table Smart.SaleHistory
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.SaleHistory'
End
Go

Create Table Smart.SaleHistory
( 
	DeliveryDate Date,
	SAPAccountNumber bigint,
	SAPMaterialID varchar(12),
	Quantity Float
)
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.SaleHistory created'
Go

/*
0107	201902070933	5mins -- need to redo
0108	201902070959    7mins -- need to redo

*/
Insert Into Smart.SaleHistory 
Select * From OpenQuery(RM, 
'SELECT IV.DELIVERY_DATE DELIVERY_DATE, IV.CUSTOMER_NUMBER ACCOUNT_NUMBER, ID.ITEM_NUMBER, SUM(ID.CASEQTY) DELIVERYCASEQTY 
FROM ACEUSER.INVOICE_MASTER IV, ACEUSER.INVOICE_DETAIL ID, ACEUSER.ITEM_MASTER IM 
WHERE TO_CHAR(IV.DELIVERY_DATE, ''YYYY-MM-DD'') = ''2019-01-08'' 
AND IV.ORDER_STATUS IN (6,7) 
AND SUBSTR(ID.ITEM_NUMBER, 1, 1) IN (1,2) 
AND IV.INVOICE_NUMBER = ID.INVOICE_NUMBER 
AND ID.ITEM_NUMBER = IM.ITEM_NUMBER 
AND IV.LOCATION_ID = IM.LOCATION_ID
AND IV.TYPE = ''D'' 
AND ID.CASEQTY > 0 
AND ROWNUM < 10 
AND IM.MATERIAL_TYPE IN (''FERT'', ''HAWA'')
GROUP BY IV.LOCATION_ID, IV.CUSTOMER_NUMBER, IV.DELIVERY_DATE, ID.ITEM_NUMBER ')
Go

Select Distinct DeliveryDate
From Smart.SaleHistory 
Order By DeliveryDate
