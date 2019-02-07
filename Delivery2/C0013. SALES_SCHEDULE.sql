Use Portal_Data
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

--4/2/2006

Update [Portal_Data].[BCMyday].[Config] 
Set Value = Null
Where ConfigID = 61 

-----------------------------------------------------
-- 4. RouteSchedule ----------------------------------
TRUNCATE TABLE Staging.RMRouteSchedule;

INSERT INTO Staging.RMRouteSchedule (
	ROUTE_NUMBER
	,CUSTOMER_NUMBER
	,LOCATION_ID
	,FREQUENCY
	,START_DATE
	,DEFAULT_DELIV_ROUTE
	,SEQUENCE_NUMBER
	,SEASONAL
	,SEASONAL_START_DATE
	,SEASONAL_END_DATE
	)
SELECT ROUTE_NUMBER
	,CUSTOMER_NUMBER
	,LOCATION_ID
	,FREQUENCY
	,START_DATE
	,DEFAULT_DELIV_ROUTE
	,SEQUENCE_NUMBER
	,SEASONAL
	,SEASONAL_START_DATE
	,SEASONAL_END_DATE
From OpenQuery(RM_QA, '
	SELECT ROUTE_NUMBER,
	CUSTOMER_NUMBER, 
	LOCATION_ID, 
	FREQUENCY, 
	START_DATE, 
	DEFAULT_DELIV_ROUTE , 
	SEQUENCE_NUMBER,
	SEASONAL ,
	SEASONAL_START_DATE, 
	SEASONAL_END_DATE
	FROM ACEUSER.ROUTE_SCHEDULE RS
	WHERE LOCATION_ID NOT IN (SELECT location_id FROM ACEUSER.SALES_SCHEDULE_LOCATION_CONFIG WHERE ACTIVE=1 and CONFIG_VALUE=1)
 	UNION
	SELECT Sales_Route, 
	CUSTOMER_NUMBER, 
	LOCATION_ID,
	case length(replace(weeks_serviced, '' '', '''')) when 1 THEN ''M''when 2 THEN ''B'' when 4 THEN ''W'' else ''A'' END as FREQUENCY,
	START_DATE,  
	NULL AS DEFAULT_DELIV_ROUTE, 
	SCHEDULE_MAP AS SEQUENCE_NUMBER,
			''0'' AS SEASONAL , 
	TO_DATE(''02-APR-06'', ''DD-MON-YY'') SEASONAL_START_DATE, 
	TO_DATE(''31-DEC-99'', ''DD-MON-YY'') SEASONAL_END_DATE
	FROM ACEUSER.SALES_SCHEDULE
	WHERE LOCATION_ID IN (SELECT location_id FROM ACEUSER.SALES_SCHEDULE_LOCATION_CONFIG WHERE ACTIVE=1 and CONFIG_VALUE=1)
')
Go

Alter PROC ETL.pStageRM
AS
	/*
		1. Location
		2. Accounts
		3. Route Master
		4. Route Schedule
		5. Item Master
		6. Package
		7. Employee
		8. POI Category
		9. POI Postion

		*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 1. Locations
	TRUNCATE TABLE Staging.RMLocation

	INSERT INTO Staging.RMLocation (
		LOCATION_ID
		,LOCATION_NAME
		,LOCATION_ADDR1
		,LOCATION_ADDR2
		,LOCATION_CITY
		,LOCATION_STATE
		,LOCATION_ZIP
		,LOCATION_PHONE
		,LOCATION_FAX
		,COMPANY_NAME
		,SUPPLIER_LOCATION_NUMBER
		)
	SELECT LOCATION_ID
		,LOCATION_NAME
		,LOCATION_ADDR1
		,LOCATION_ADDR2
		,LOCATION_CITY
		,LOCATION_STATE
		,LOCATION_ZIP
		,LOCATION_PHONE
		,LOCATION_FAX
		,COMPANY_NAME
		,SUPPLIER_LOCATION_NUMBER
	FROM RM..ACEUSER.LOCATION;

	-- 2. Load Accounts into Staging
	TRUNCATE TABLE Staging.RMAccount;

	INSERT INTO Staging.RMAccount (
		CUSTOMER_NUMBER
		,LOCATION_ID
		,CUSTOMER_NAME
		,CUSTOMER_STREET
		,CITY
		,STATE
		,POSTAL_CODE
		,CONTACT_PERSON
		,PHONE_NUMBER
		,LOCAL_CHAIN
		,CHANNEL
		,ACTIVE
		)
	SELECT CUSTOMER_NUMBER
		,LOCATION_ID
		,CUSTOMER_NAME
		,CUSTOMER_STREET
		,CITY
		,STATE
		,POSTAL_CODE
		,CONTACT_PERSON
		,PHONE_NUMBER
		,LOCAL_CHAIN
		,CHANNEL
		,ACTIVE
	FROM RM..ACEUSER.CUSTOMERS

	-- 3. Route Master
	TRUNCATE TABLE Staging.RMRouteMaster;

	INSERT INTO Staging.RMRouteMaster (
		ROUTE_NUMBER
		,ROUTE_DESCRIPTION
		,ACTIVE_ROUTE
		,ROUTE_TYPE
		,LOCATION_ID
		,DEFAULT_EMPLOYEE
		,ACTIVE
		,DISPLAYALLOWANCE
		,SALES_GROUP
		)
	SELECT ROUTE_NUMBER
		,ROUTE_DESCRIPTION
		,ACTIVE_ROUTE
		,ROUTE_TYPE
		,LOCATION_ID
		,DEFAULT_EMPLOYEE
		,ACTIVE
		,DISPLAYALLOWANCE
		,SALES_GROUP
	FROM RM..ACEUSER.ROUTE_MASTER

	-----------------------------------------------------
	-- 4. RouteSchedule ----------------------------------
	TRUNCATE TABLE Staging.RMRouteSchedule;

	INSERT INTO Staging.RMRouteSchedule (
		ROUTE_NUMBER
		,CUSTOMER_NUMBER
		,LOCATION_ID
		,FREQUENCY
		,START_DATE
		,DEFAULT_DELIV_ROUTE
		,SEQUENCE_NUMBER
		,SEASONAL
		,SEASONAL_START_DATE
		,SEASONAL_END_DATE
		)
	SELECT ROUTE_NUMBER
		,CUSTOMER_NUMBER
		,LOCATION_ID
		,FREQUENCY
		,START_DATE
		,DEFAULT_DELIV_ROUTE
		,SEQUENCE_NUMBER
		,SEASONAL
		,SEASONAL_START_DATE
		,SEASONAL_END_DATE
	From OpenQuery(RM_QA, '
		SELECT ROUTE_NUMBER,
		CUSTOMER_NUMBER, 
		LOCATION_ID, 
		FREQUENCY, 
		START_DATE, 
		DEFAULT_DELIV_ROUTE , 
		SEQUENCE_NUMBER,
		SEASONAL ,
		SEASONAL_START_DATE, 
		SEASONAL_END_DATE
		FROM ACEUSER.ROUTE_SCHEDULE RS
		WHERE LOCATION_ID NOT IN (SELECT location_id FROM ACEUSER.SALES_SCHEDULE_LOCATION_CONFIG WHERE ACTIVE=1 and CONFIG_VALUE=1)
 		UNION
		SELECT Sales_Route, 
		CUSTOMER_NUMBER, 
		LOCATION_ID,
		case length(replace(weeks_serviced, '' '', '''')) when 1 THEN ''M''when 2 THEN ''B'' when 4 THEN ''W'' else ''A'' END as FREQUENCY,
		START_DATE,  
		NULL AS DEFAULT_DELIV_ROUTE, 
		SCHEDULE_MAP AS SEQUENCE_NUMBER,
				''0'' AS SEASONAL , 
		TO_DATE(''02-APR-06'', ''DD-MON-YY'') SEASONAL_START_DATE, 
		TO_DATE(''31-DEC-99'', ''DD-MON-YY'') SEASONAL_END_DATE
		FROM ACEUSER.SALES_SCHEDULE
		WHERE LOCATION_ID IN (SELECT location_id FROM ACEUSER.SALES_SCHEDULE_LOCATION_CONFIG WHERE ACTIVE=1 and CONFIG_VALUE=1)
	')

	-----------------------------------------------------
	-- 5. ItemMaster ----------------------------------
	TRUNCATE TABLE Staging.RMItemMaster

	INSERT INTO Staging.RMItemMaster
	SELECT DISTINCT Location_ID
		,ITEM_NUMBER,Material_Status
	FROM RM..ACEUSER.ITEM_MASTER
	WHERE Active = 1

	--------------------------------------------
	-- 6. Package -------------------------------
	--Load Packages into Staging
	TRUNCATE TABLE Staging.RMPackage

	INSERT INTO Staging.RMPackage
	SELECT PACKAGEID
		,DESCRIPTION
		,Substring(PACKAGEID, 1, 3) SAPPackageTypeID
		,SUBSTRING(PACKAGEID, 4, 2) SAPPackageConfigID
	FROM RM..ACEUSER.PACKAGE;

	--------------------------------------------------------
	-- 7. Employee -----------------------------------------
	TRUNCATE TABLE Staging.RMEmployee

	INSERT INTO Staging.RMEmployee
	SELECT EMPLOYEEID
		,JOBROLE
		,FIRSTNAME
		,LASTNAME
		,LOCATION_ID
		,ACTIVE
		,GSN
	FROM RM..ACEUSER.EMPLOYEES

	------------------------------------------------------
	-- 8. POI Category -------------------------------------
	TRUNCATE TABLE Staging.RMPoiCategory

	INSERT INTO Staging.RMPoiCategory
	SELECT POICAT_ID
		,BEVCAT_GL1
		,BRANDPKG_GL2
		,BEVID
		,TRADEMARK
		,PACKAGETYPE
		,PACKAGEID
		,GL1_SORT
		,GL2_SORT
		,ACTIVE
	FROM RM..ACEUSER.POI_CATEGORY

	--------------------------------------------------------
	-- 9. POI Position -------------------------------------
	TRUNCATE TABLE Staging.RMPoiPosition

	INSERT INTO Staging.RMPoiPosition
	SELECT POIPOS_ID
		,POIPOS_DESC
		,CHANNEL
		,SORT_ORDER
		,ACTIVE
	FROM RM..ACEUSER.POI_POSITION

Go

/*
  
RM_QA.WORLD =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = bplndb07.dpsg.net)(PORT = 1527))
    )
    (CONNECT_DATA =
        (SERVICE_NAME = ACE60Q0)
    )
  )

*/