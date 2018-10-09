
With JobHistory As
(
	select 
	j.name as 'JobName',
	s.step_id as 'Step',
	s.step_name as 'StepName',
	msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
	((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
			as 'RunDurationMinutes'
	From msdb.dbo.sysjobs j 
	INNER JOIN msdb.dbo.sysjobsteps s 
	ON j.job_id = s.job_id
	INNER JOIN msdb.dbo.sysjobhistory h 
	ON s.job_id = h.job_id 
	AND s.step_id = h.step_id 
	AND h.step_id <> 0
	where j.enabled = 1  
)

Select * From JobHistory
Order By JobName, RunDateTime, Step


Select JobName, Count(RunDateTime) NumberOfRecentRuns, Max(RunDateTime) LatestRunDateTime
From JobHistory
Group By JobName
Order by JobName


select 
 j.name as 'JobName',
 run_date,
 run_time,
 msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
From msdb.dbo.sysjobs j 
INNER JOIN msdb.dbo.sysjobhistory h 
 ON j.job_id = h.job_id 
where j.enabled = 1  --Only Enabled Jobs
order by JobName, RunDateTime desc

With His As
(
	Select j.name as 'JobName', 
		msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime',
		((run_duration/10000*3600 + (run_duration/100)%100*60 + run_duration%100 + 31 ) / 60) 
			as 'RunDurationMinutes', Run_Status, Message
		--h.*
	From msdb.dbo.sysjobs j 
	INNER JOIN msdb.dbo.sysjobhistory h 
	 ON j.job_id = h.job_id 
	Where Step_id = 0
),
Job As
(
Select JobName, Count(RunDateTime) Runs, Max(RunDateTime) LastRun, Avg(RunDurationMinutes) AvgRunTime
From His
Group By JobName
)

Select j.*, h.run_status LastRunStatus, h.message LastRunMessage
From Job j
Join His h on j.JobName = h.JobName And j.LastRun = h.RunDateTime
Where h.run_Status = 0



Order By JobName





