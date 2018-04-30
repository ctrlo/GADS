

# Force a user to enter a value in a specific format

**If you want the values in a text field to be in a specific format, you can use a regular expression to describe the pattern a value must follow to be valid. **

For example:

* If values in a text field must contain the word "project", you could express this condition as: &nbsp;.\*project.\*&nbsp;
* If &nbsp;all value must start with the letters "BTN", you would express this condition as: BTN.\*
* If a value has to start with a single letter followed by a number, you would use: [A-Za-z][0-9]+

[More about regular expressions](http://www.regular-expressions.info/tutorial.html)

If you do force an input format in a text field, it's good to tell your users what format you want. You can use the **Help text for users** field when you add a field to do this.&nbsp;