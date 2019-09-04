var cols = 12;
var margin = [10, 10];
var containerPadding = [0, 10];
var rowHeight = 80;
var root = document.getElementById('ld-app');
if (root) {
  var containerWidth = root.offsetWidth;
  var colWidth = (containerWidth - margin[0] * (cols - 1) - containerPadding[0] * 2) / cols;

  function calculateStyle(x, y, w, h) {
    var left = Math.round((colWidth + margin[0]) * x + containerPadding[0]);
    var top = Math.round((rowHeight + margin[1]) * y + containerPadding[1]);
    var width = Math.round(colWidth * w + Math.max(0, w - 1) * margin[0]);
    var height = Math.round(rowHeight * h + Math.max(0, h - 1) * margin[1]);
    return "left: ".concat(left, "px; top: ").concat(top, "px; width: ").concat(width, "px; height: ").concat(height, "px; position: absolute;");
  };

  var widgets = root.querySelectorAll("div");
  var bottom = 0;
  var currentY;
  for (var i = 0; i < widgets.length; i++) {
    var grid = JSON.parse(widgets[i].getAttribute('data-grid'));
    currentY = grid.y + grid.h;
    if (currentY > bottom) bottom = currentY;
    widgets[i].setAttribute("style", calculateStyle(grid.x, grid.y, grid.w, grid.h));
  }

  var containerHeight = bottom * rowHeight +
    (bottom - 1) * margin[1] + containerPadding[1] * 2
  root.setAttribute("style", "height: " + containerHeight + "px")
}
