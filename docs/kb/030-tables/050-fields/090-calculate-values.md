

# Using Lua to return values for RAG and calculated fields

**Calculated value fields and RAG status fields automatically generate values based on the values of other fields in a table. For both these field types, you define your calculation using a sub-set of the [Lua programming language](https://www.lua.org/pil/contents.html).**

A calculation consists of a Lua `evaluate` function with its parameters being the values required from other fields. So for example, if you wanted to create a&nbsp;*continent*field that depended on the value in the *country&nbsp;*field, you might use the following calculation for the continent field:

```

function evaluate (country)

if country == "Greece" then

	return "Europe"

elseif country == "Japan" then

	return "Asia"

end

end
```

You reference any&nbsp;**field&nbsp;**you want to evaluate using its short name inside round brackets (in this case *country*), and you include the **field values** in inverted commas.

In Lua the relational operators are:

* Equal to ==
* Not equal to ~=
* Less than &lt;
* Greater than &gt;
* Less than or equal to &lt;=
* Greater than or equal to &gt;=