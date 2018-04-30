

# RAG status field

**You can use a RedAmberGreen (RAG) status field to automatically generate colour-coded indicators based on the values of other fields in a record.**

The conditions for the red, amber and green indicators will always be checked in that order. If a record meets more than one of the conditions, it will show the red over the amber or the green.

Use basic Lua programming to stipulate the conditions for red, amber and green indicators to be displayed. If none of the conditions match, the field will be grey. For more information see:&nbsp;[Using Lua in Linkspace&nbsp;](/130-lua.md)