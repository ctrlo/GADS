

# Using regular expressions to match field values

**You can hide or display a field on the Add a record or Edit record screens based on the value a user enters in another field. To set the conditions under which a field is displayed you can either type in the exact text or number that the other field needs to match, or you can use a regular expression to define the match.**

| You want the field to be displayed if | &nbsp; | 
| --- | --- |
| The value entered in the other field is an exact match | Enter the text you want to match | 
| Any value is entered in the other field | `.+` | 
| The value entered in the other field contains the word "project" | `\*project.\*` | 
| The value entered in the other field starts with the letters "BTN" | `BTN.\*` | 
| If one of three values i.e. 1,2 0r 3 is entered in the other field | `(1 | 2 | 3)` |
| If the value entered in the other field is greater than 300 but less than 1000 | `[3-9][0-9][0-9]` |
| If a specific node in a tree is selected\* | `(.\*#)?Node name` |

\*If you want to use the tree node's full path, you need to include a hash between each level. For example, if you were using a tree for a field on *Regions*, and you only wanted to display a field if a user had selected *Amhara*in *Ethiopia*, you would need to express your match as: "Regions#Africa#Ethiopia#Amhara" i.e. "Level 1#Level 2#Level 3#Level 4#Node value"

[More about regular expressions](http://www.regular-expressions.info/tutorial.html)