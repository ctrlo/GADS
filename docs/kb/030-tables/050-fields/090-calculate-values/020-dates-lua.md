

# Working with dates in your Lua calculations

**Values in Linkspace date fields are passed as Lua table values with the indexes *year*, *month*, *day&nbsp;*and *epoch*. You can reference current date and time by referencing the operating system date and time by using `os.time`.**

Where you are evaluating dates, the value returned by your calculation should be in [UNIX epoch time](https://www.epochconverter.com/), which will then be converted to a full date by Linkspace. In epoch time, you use seconds to express time, so:

1 hour = 3600
<br>1 day = 86400
<br>1 week = 604800
<br>1 month (30.44 days) = 2629743
<br>1 year = (365.24 days) = 31556926

### Example of a calculation for a RAG field that uses dates

For example, you could use a RAG status field to keep track of reviews. Completed reviews would be “green”, those scheduled within the next 30 days would be “amber” and those with no scheduled date would be “red”.

```
function evaluate (reviewdate)

if reviewdate == nil then
            return "red"
    end

if reviewdate.epoch < os.time() then
        return "green"
    end
    if reviewdate.epoch < os.time() + (86400 \\\* 30) then
        return "amber"
    end

end
```

In this calculation you reference the current date using os.time, and convert the time to epoch time. See below for a full list of the Lua functions that are enabled in Linkspace

## Date range fields

Date ranges are also passed as Lua tables with the table indexes *from*and *to*which contain the same tables a date field would (i.e. with the tables indexes *year*, *month*, *day*and *epoch*).

### Example of calculated values using a date range field

```
function evaluate (projectschedule)
if projectschedule == nil then
return "No project schedule"
end
if projectschedule.from.epoch < os.time() then
return "Project underway"
end
if projectschedule.from.epoch < os.time() + (86400 \* 30) then
return "Starts within 30 days"
end
```