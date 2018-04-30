

# Working tree fields in your Lua calculations

**Tree values are passed as Lua table values with the indexes *value* and *parents*. *Value* contains the actual value of the field and *parents* is another table containing all the node's parents (starting at *parent1* for the top level and continuing sequentially).**

## Example of calculated values based on tree nodes

You can evaluate a tree field according to the final node selected, or according to a parent node. For example, if you wanted to auto-fill a Project Office field based on the region (short name = *regions*) in which the project was based you could use the following if your region field was set up as a tree field:

```
 function evaluate (regions)
    if regions.parents.parent1 == "nil" then
        return "None"
    end

    if regions.parents.parent1 == "Australia" then
        return "Asia Pacific"
    end

    if regions.parents.parent1 == "South Africa" then
        return "Africa Middle East"
    end

    if regions.value == "Hampshire" then
        return "UK South East"
    end

    if regions.value == "Yorkshire" then
        return "UK North"
    end
end
```