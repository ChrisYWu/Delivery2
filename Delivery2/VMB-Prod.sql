-- This Version automatically calculates start and end date for the last week.
use Portal_Data
Go
 
Declare @startdate as date
Declare @enddate as date
 
Select @startdate = DateAdd(day, -5 - DatePart(dw, Convert(Date, GetDate())), Convert(Date, GetDate()))
Select @startdate = DateAdd(Week, -0, @STartDAte)
Select @enddate = DateAdd(Day, 6, @startdate)

Select @StartDate StartDate, @EndDate EndDate, @@SERVERNAME Server

Declare @ExceptionCount int

select @ExceptionCount = count(*)
from Shared.ExceptionLog
where
LastModified >= @startdate -- Monday of the week
and LastModified < @enddate  -- Sunday of the week
and AppliationID=1016;					


Select @StartDate StartDate, @EndDate EndDate, @ExceptionCount ExceptionCount

select @StartDate StartDate, @EndDate EndDate, Source, detail, detail detail1, count(*)
from Shared.ExceptionLog
where 
LastModified >= @startdate -- Monday of the week
and LastModified < @enddate  -- Sunday of the week
and AppliationID=1016				
group by Source, detail
order by Source, detail
