# Working with numbers in Lua

## Working out the average of several numerical values

```
function evaluate (score1, score2, score3)
    total = 0
    count = 0
    if score1 ~= nil then
        total = total + score1
        count = count + 1
    end
    if score2 ~= nil then
        total = total + score2
        count = count + 1
    end
    if score3 ~= nil then
        total = total + score3
        count = count + 1
    end
    if count == 0 then
        return
    end
    return (total / count)
end
```