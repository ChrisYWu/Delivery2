-- [11298119,12269913,11296557,11298848,11297027,11297784,12332468,11985210,11484777,12300461

Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Exec Operation.pGetMerchStoreDelivery1 @DeliveryDate='2018-12-05', 
								@SAPAccountNumber='11298119,12269913,11296557,11298848,11297027,11297784,12332468,11985210,11484777,12300461',
								@IsDetailNeeded=0
								,
								 
								@Debug=1


Insert Into Archive.Mesh_OrderItem
Select * From Mesh.OrderItem
Where RMOrderID in (
	Select *
	From Mesh.CustomerOrder
	Where DeliveryDateUTC < DateAdd(Day , -90, Convert(Date, GetDate()))
)

Select *
From Archive.Mesh_OrderItem


Select Count(*)
From Mesh.CustomerInvoice


