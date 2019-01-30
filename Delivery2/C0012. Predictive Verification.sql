Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From Apacheta.FleetLoader
Where SESSION_DATE between '2018-10-01' And '2018-12-30'
And LOCATION_ID = '12274874'
And SKU = 10000862
Order By Session_Date

Select Distinct SESSION_DATE
From Apacheta.FleetLoader
Where SESSION_DATE > '2018-12-31'
And LOCATION_ID = '12274874'
order by SESSION_DATE 
