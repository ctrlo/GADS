# API SPECIFICATION PROPOSAL
This short document will explain what the expected behaviour and return values of each API call are. Each widget should have a unique ID. The grid itself consists of 12 columns and as many rows as the layout needs. The height of a row is 80px, the width of a column is the width of the viewport divided by 12. This means the actual dimensions of the grid items will be different for different screen sizes. To avoid name conflicts all ids and classes are prefixed with "ld-".

## Save Layout
url: `PUT {dashboard_endpoint}/dashboard/{dashboard_id}`  
body: The layout object in JSON  
body example:  
```JSON
[
  {"i": "6ba43bd8-00a2-4464-bd51-634fbea1148b", "x": 0, "y": 0, "w": 4, "h": 2, "static": false, "minW": 4},
  {"i": "3b104202-8fa9-4421-ac24-54ed9fd2f93e", "x": 4, "y": 0, "w": 2, "h": 2, "static": false},
  {"i": "c59d3ca0-25ee-4f04-8e55-f6545bd0622e", "x": 6, "y": 0, "w": 6, "h": 4, "static": false}
]
```
return: 200 OK or 404 if dashboard not found  
description: After moving, adding, resizing or deleting any of the widgets, the layout will change. This layout needs to be saved on the server. Right now, we are saving on every layout change. We can also make a dedicated save button and only save when the button is pressed or a widget is deleted.

## Create widget
url: `POST {dashboard_endpoint}/widget?type={type}`  
return: The unique identifier of the newly created widget.  
description: This call is used to add a widget to the dashboard.  
return example:  
```
6ba43bd8-00a2-4464-bd51-634fbea1148b
```

## Widget HTML
url: `GET {dashboard_endpoint}/widget/{widget_id}`  
return: The inner html of a widget. This needs to be responsive to make sure it will properly fill the assigned space in the grid.   
description: This call is used when a widget has been changed and needs to be refreshed.

## Delete widget
url: `DELETE {dashboard_endpoint}/widget/{widget_id}`  
return: 200 OK or 404 if it does not exist  
description: When a widget is deleted from the dashboard, two API calls are made. Firstly, the layout is changed, so the [Save Layout](#save-layout) call will be used. Secondly the widget will be deleted from the server by using this delete call.

## Edit form HTML
url: `GET {dashboard_endpoint}/widget/{widget_id}/edit`  
return: The html of the edit form of a widget.  
description: This call is used when a user has pressed on the **Edit** button of a widget. A modal will be opened and the form html provided will be injected into the modal. As the modal wrapper provides a **Save** button and injects a hidden submit button, the form itself does not need its own submit button. **IMPORTANT:** Use the action attribute to indicate where to post the form to. This url will be used to POST the serialized form to.  
example:  
```html
<form action="/widget/6ba43bd8-00a2-4464-bd51-634fbea1148b">
  First name:<br>
  <input type="text" name="firstname">
  <br>
  Last name:<br>
  <input type="text" name="lastname">
</form>
```

# Base HTML to provide
In order to make this app viewable on IE8, the full HTML needs to be delivered. If available, React will take over and make the application interactive. To make this possible, the HTML needs to adhere to a template like so:

```html
<div
  id="ld-app"
  class="react-grid-layout"
  data-dashboard="23"
  data-dashboard-endpoint="/api/dashboard"
  data-widget-types='["graph", "chart", "table", "bar"]'>
  <div
    class="ld-widget-container"
    data-grid='{"i": "23", "x": 0, "y": 0, "w": 4, "h": 2, "minW": 4}'>
    <widgetHTML />
  </div>
  <div
    class="ld-widget-container"
    data-grid='{"i": "24", "x": 4, "y": 0, "w": 2, "h": 2}'>
    <widgetHTML />
  </div>
  <div
    class="ld-widget-container"
    data-grid='{"i": "25", "x": 6, "y": 0, "w": 6, "h": 4}'>
    <widgetHTML />
  </div>
</div>
```

Where `<widgetHTML />` should be replaced with the HTML of each widget.  
`data-dashboard-endpoint` is used as the base url for all api calls.  
`data-dashboard` is the id of the dashboard. This is used for the api calls.  
`data-widget-types` is an array of all widget types (in JSON) that can be used in the [Create widget](#create-widget) call  
`data-grid` is used by React to transform the static HTML into an interactive dashboard. It is simply the layout object spread amongst the widgets. This object should use these properties: (properties prefixed with "?" are optional)
```js
{

  // A string corresponding to the widget id
  i: string,

  // These are all in grid units, not pixels
  x: number,
  y: number,
  w: number,
  h: number,
  minW: ?number = 0,
  maxW: ?number = Infinity,
  minH: ?number = 0,
  maxH: ?number = Infinity,

  // If true, equal to `isDraggable: false, isResizable: false`.
  static: ?boolean = false,
  // If false, will not be draggable. Overrides `static`.
  isDraggable: ?boolean = true,
  // If false, will not be resizable. Overrides `static`.
  isResizable: ?boolean = true
}
```
<!-- The style of each widget-container needs to be calculated using the layout as follows:  
```js
const cols = 12 // We use 12 columns
const containerWidth = 1600 // Assume a desktop screen width of 1600
const margin = [10, 10] // horizontal and vertical margin between each grid item
const containerPadding = [10, 10] // horizontal and vertical padding for the container
const rowHeight = 80 // We currently use a row height of 80

// The above constants are all configurable

const colWidth = (containerWidth - margin[0] * (cols - 1) - containerPadding[0] * 2) / cols

const style = {
  left: Math.round((colWidth + margin[0]) * x + containerPadding[0]),
  top: Math.round((rowHeight + margin[1]) * y + containerPadding[1]),
  width: Math.round(colWidth * w + Math.max(0, w - 1) * margin[0]),
  height: Math.round(rowHeight * h + Math.max(0, h - 1) * margin[1])
}
``` -->

When React is available everything inside of the "ld-app" div will be re-rendered by React. Otherwise, the HTML is rendered as is.