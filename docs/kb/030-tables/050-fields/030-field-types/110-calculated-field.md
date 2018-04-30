

# Calculated value field

**A calculated field automatically generates values based on the values of other fields. The values you generate and the values you use in your calculations can be numbers, but they don't have to be. You use the &nbsp;Lua programming language to return the value of the calculated field. For more information see:&nbsp;[Using Lua in Linkspace](../130-lua.md)&nbsp;**

## To set up a calculated field

When you [add a new field](../020-add-field.md), to set it as a calculated value field you need to:

1. Select&nbsp;**Calculated value** as your field **Type**. You will then see your calculated field options.
2. In the **Return value conversion&nbsp;** dropdown box, select whether the final value will be a string (i.e text and/or numbers), a date, an integer or a decimal number.
3. In the **Calculation&nbsp;** box, use the [Lua programming language](../130-lua.md) for your calculation.&nbsp;
4. If you want changes in your calculated field to trigger any [alerts](../../../070-views/090-alerts/010-set-up-alert.md) you set up, untick the checkbox for **Alerts**.
5. &nbsp;Decide when you want the field to update itself. You can either choose for the calculated value to change as soon as any changes are made to fields that are included in the calculation (**Update all existing values immediately**), or for the field to update overnight (**Do not immediately update all existing value**).&nbsp;
6. Complete the rest of the fields and click the **Save** button.&nbsp;