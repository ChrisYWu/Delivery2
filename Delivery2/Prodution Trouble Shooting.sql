use Merch
Go
With Err As
(
	Select ModifiedDate, convert(Date, ModifiedDate) ErrorDate, Convert(varchar(10), convert(Date, ModifiedDate)) + ' - ' + Datename(weekday, ModifiedDate)  ErrorDateText, 
	Datename(weekday, ModifiedDate) WD, 
	convert(Time, ModifiedDate) ErrorTime, DATEPART(HOUR,  ModifiedDate) ErrorHour, Substring(Exception, 1, 50) Exception 
	From Setup.WebAPILog
	--Where convert(Date, ModifiedDate) between '4-2-2018' and '4-8-2018'
	Where convert(Date, ModifiedDate) between '3-5-2018' and '4-8-2018'
	And Exception like 'Execution Timeout Expired.%'
)

Select *
From Err
Where ErrorHour Between 5 and 9

/*
With Job As
(
	select 
	 j.name as 'JobName',
	 run_date,
	 run_time,
	 msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
	 convert(time, msdb.dbo.agent_datetime(run_date, run_time)) Start_Time,
	 dateadd(second, ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 )) , convert(time, msdb.dbo.agent_datetime(run_date, run_time))) End_Time,
	 Run_Duration,
	  ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 )) 
			  as 'RunDurationInSeconds',
	 ((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
			  as 'RunDurationInMinutes'
	From msdb.dbo.sysjobs j 
	INNER JOIN msdb.dbo.sysjobhistory h 
	 ON j.job_id = h.job_id 
	where j.enabled = 1  --Only Enabled Jobs
),

JobMor As
(
Select *, DatePart(Hour, Start_Time) Start_Hour, DatePart(Hour, End_Time) End_Hour
From Job
)

Select Distinct
JobName, DateName(WEEKDAY, Convert(Date, RunDateTime)) DW, Convert(Date, RunDateTime) RunDate, 
Convert(varchar(10), Convert(Date, RunDateTime)) + ' - ' + DateName(WEEKDAY, Convert(Date, RunDateTime)) DisplayDate,
Start_Time, End_Time, RunDurationInSeconds
From JobMor
Where (Start_Hour between 5 and 9
Or end_hour between 5 and 9)
And RunDateTime Between '3-5-2018' and '4-8-2018'
--Order by RunDurationInSeconds Desc


--Where DatePart(Hour, Start_Time) > 5 and 
--Or  DatePart(Hour, End_Time) < 9
--order by JobName, RunDateTime desc


--Select * From Err Order By ModifiedDate;

--Select ErrorDate, WD, Count(*) TotalErrors
--From Err
--Where ErrorHour Between 5 And 9
--Group By ErrorDate, WD
--Order By ErrorDate, WD

*/


  Update [Mesh].[DeliveryRoute]
  Set ActualStartTime = null,
  ActualCompleteTime = null,
  ActualStartFirstName = null,
  ActualStartGSN = null,
  ActualStartLastName = null, 
  ActualStartPhoneNumber = null,
  ActualStartLongitude = null,
  ActualStartLatitude = null
  Where DeliveryDateUTC = '2018-03-29'

  Delete
  From Mesh.DeliveryStop
  Where DeliveryDateUTC = '2018-03-29'

  Delete 
  From [Mesh].[Resequence]
  Where DeliveryDateUTC = '2018-03-29'


