

# Calculations for RAG status fields&nbsp;

**The return values for the calculation in a RAG status field should always be “red”, “amber” or “green”. You can also return nothing, which will be interpreted as grey. Any other values, or code causing errors, will display purple.**

## Example 1

For example, you could use a RAG status field to keep track of reviews. Completed reviews would be “green”, those scheduled within the next 30 days would be “amber” and those with no scheduled date would be “red”.

```
function evaluate (reviewdate)

if reviewdate == nil then
            return "red"
    end

if reviewdate.epoch < os.time() then
        return "green"
    end

if reviewdate.epoch < os.time() + (86400 \* 30) then
        return "amber"
    end
end
```

In this calculation you reference the current date using os.time, and convert the time to epoch time.