use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('ETL.pLoadDeliveryPlanFromRN'))
Begin
	Drop Proc ETL.pLoadDeliveryPlanFromRN
	Print '* ETL.pLoadDeliveryPlanFromRN'
End
Go

/*
--------------------------------------------------------------------------------------------------------------------------------------------
-- Generates manifest data for all routes belongiong to a given branch (location_id) for current system date. Provides stop information with
-- arrival times, departure times, service times, travel times. Includes branch times at start of route and end of route.
-- Does not include break times. To specify a branch replace the first where clause in each query.
-- ALL TIMES in UTC
--------------------------------------------------------------------------------------------------------------------------------------------
 SELECT r.route_id route_number, 'STORE' stop_type, s.location_id stop_id,  s.travel_time travel_time_inseconds,  TO_CHAR(s.arrival, 'YYYY-MM-DD HH24:MI') ArrivalTime,  
        s.service_time halt_time_inseconds, TO_CHAR(s.arrival+numToDSInterval( s.service_time, 'second' ), 'YYYY-MM-DD HH24:MI') ExpectedDepartureTime,
        r.location_region_id_origin salesoffice_id,  e.first_name driver_fname, e.last_name driver_lname, e.work_phone_number driver_phone_num
   FROM rs_route r, rs_stop s,  ts_employee e
  WHERE r.location_region_id_origin='10881332' AND TO_CHAR(r.start_time, ''YYYY-MM-DD'') = TO_CHAR(sysdate, ''YYYY-MM-DD'')
    AND s.rn_session_pkey = r.rn_session_pkey 
    AND s.route_pkey = r.pkey  
    AND s.sequence_number != -1 
    AND r.DRIVER1_ID = e.ID
  UNION
 SELECT r.route_id route_number, 'BRANCHSTART' stop_type, r.location_region_id_origin stop_id, 0 travel_time_inseconds, TO_CHAR(r.start_time, 'YYYY-MM-DD HH24:MI') ArrivalTime,
        preroute_time halt_time_inseconds,   TO_CHAR(r.start_time+numToDSInterval( r.preroute_time, 'second' ),'YYYY-MM-DD HH24:MI') ExpectedDepartureTime,
        r.location_region_id_origin salesoffice_id, e.first_name driver_fname, e.last_name driver_lname, e.work_phone_number driver_phone_num
   FROM rs_route r, ts_employee e
  WHERE r.location_region_id_origin='10881332' AND TO_CHAR(r.start_time, ''YYYY-MM-DD'') = TO_CHAR(sysdate, ''YYYY-MM-DD'')
    AND r.DRIVER1_ID = e.ID
  UNION
 SELECT r.route_id route_number, 'BRANCHRETURN' stop_type, r.location_region_id_origin stop_id, 0 travel_time_inseconds,  TO_CHAR(r.complete_time-numToDSInterval( r.postroute_time, 'second' ), 'YYYY-MM-DD HH24:MI') ArrivalTime,
        postroute_time halt_time_inseconds,  TO_CHAR(r.complete_time, 'YYYY-MM-DD HH24:MI') ExpectedDepartureTime,
        r.location_region_id_origin salesoffice_id, e.first_name driver_fname, e.last_name driver_lname, e.work_phone_number driver_phone_num
   FROM rs_route r, ts_employee e
  WHERE r.location_region_id_origin='10881332' AND TO_CHAR(r.start_time, ''YYYY-MM-DD'') = TO_CHAR(sysdate, ''YYYY-MM-DD'')
    AND r.DRIVER1_ID = e.ID
ORDER BY salesoffice_id, route_number, ArrivalTime;
        ;

--exec ETL.pLoadDeliveryPlanFromRN

*/

Create Proc ETL.pLoadDeliveryPlanFromRN
As
Begin
	Set NoCount On;
	
	Truncate Table Staging.RNDeliveryPlan

	Insert Into Staging.RNDeliveryPlan
	Select * From OpenQuery(RN, ' 
			SELECT TO_CHAR(sysdate, ''YYYY-MM-DD'') DeliveryDate, 
				r.rn_session_pkey RNKey,
				r.route_id route_number, 
				''STORE'' stop_type, 
				s.location_id stop_id,  
				s.travel_time travel_time_inseconds,  
				s.arrival ArrivalTime,  
				s.service_time service_time_inseconds, 
				r.location_region_id_origin salesoffice_id,  
				e.ID DriverID, 
				e.first_name driver_fname, 
				e.last_name driver_lname, 
				e.work_phone_number driver_phone_num
			FROM TSDBA.rs_route r, TSDBA.rs_stop s,  TSDBA.ts_employee e
			WHERE TO_CHAR(r.start_time, ''YYYY-MM-DD'') = ''2017-04-04''
			AND s.rn_session_pkey = r.rn_session_pkey 
			AND s.route_pkey = r.pkey  
			AND s.sequence_number != -1 
			AND r.DRIVER1_ID = e.ID
			AND e.REGION_ID = r.location_region_id_origin
			')
			Union
	Select * From OpenQuery(RN, ' 
			SELECT DISTINCT
				''2017-04-04'' DeliveryDate, 
				r.rn_session_pkey RNKey,
				r.route_id route_number, 
				''BRANCHSTART'' stop_type, 
				r.location_region_id_origin stop_id, 
				0 travel_time_inseconds, 
				r.start_time ArrivalTime,
				preroute_time service_time_inseconds,   
				r.location_region_id_origin salesoffice_id, 
				e.ID DriverID, 
				e.first_name driver_fname, 
				e.last_name driver_lname, 
				e.work_phone_number driver_phone_num
			FROM TSDBA.rs_route r, TSDBA.rs_stop s, TSDBA.ts_employee e
			WHERE TO_CHAR(r.start_time, ''YYYY-MM-DD'') = ''2017-04-04''
			AND s.rn_session_pkey = r.rn_session_pkey 
			AND s.route_pkey = r.pkey  
			AND s.sequence_number != -1 
			AND r.DRIVER1_ID = e.ID
			AND e.REGION_ID = r.location_region_id_origin
			')
			Union
	Select * From OpenQuery(RN, ' 
			SELECT Distinct
				''2017-04-04'' DeliveryDate, 
				r.rn_session_pkey RNKey,
				r.route_id route_number, 
				''BRANCHRETURN'' stop_type, 
				r.location_region_id_origin stop_id, 
				0 travel_time_inseconds,  
				TO_CHAR(r.complete_time-numToDSInterval( r.postroute_time, ''second'' ), ''YYYY-MM-DD HH24:MI:SS'') ArrivalTime,
				postroute_time service_time_inseconds,
				r.location_region_id_origin salesoffice_id, 
				e.ID DriverID, 
				e.first_name driver_fname, 
				e.last_name driver_lname, 
				e.work_phone_number driver_phone_num
			FROM TSDBA.rs_route r, TSDBA.rs_stop s, TSDBA.ts_employee e
			WHERE TO_CHAR(r.start_time, ''YYYY-MM-DD'') = ''2017-04-04''
			AND s.rn_session_pkey = r.rn_session_pkey 
			AND s.route_pkey = r.pkey  
			AND s.sequence_number != -1 
			AND r.DRIVER1_ID = e.ID
			AND e.REGION_ID = r.location_region_id_origin
			')
End

Go

Print 'Creating ETL.pLoadDeliveryPlanFromRN'
Go

