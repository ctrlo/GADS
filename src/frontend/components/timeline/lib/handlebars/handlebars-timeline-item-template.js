import Handlebars from 'handlebars'

(function () {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['timelineitem'] = template({
    "1": function (container, depth0, helpers, partials, data) {
      var alias1 = container.lambda, alias2 = container.escapeExpression,
        lookupProperty = container.lookupProperty || function (parent, propertyName) {
          if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
            return parent[propertyName];
          }
          return undefined
        };

      return "                <li>"
        + alias2(alias1((depth0 != null ? lookupProperty(depth0, "name") : depth0), depth0))
        + ": "
        + alias2(alias1((depth0 != null ? lookupProperty(depth0, "value") : depth0), depth0))
        + "</li>\n";
    }, "compiler": [8, ">= 4.3.0"], "main": function (container, depth0, helpers, partials, data) {
      var stack1, helper, alias1 = depth0 != null ? depth0 : (container.nullContext || {}),
        alias2 = container.hooks.helperMissing, alias3 = "function", alias4 = container.escapeExpression,
        lookupProperty = container.lookupProperty || function (parent, propertyName) {
          if (Object.prototype.hasOwnProperty.call(parent, propertyName)) {
            return parent[propertyName];
          }
          return undefined
        };

      return "<div class=\"timeline-tippy\"\n    data-tippy-sticky=\"true\"\n    data-tippy-interactive=\"true\"\n    data-tippy-content='<div>\n        <b>Record "
        + alias4(((helper = (helper = lookupProperty(helpers, "current_id") || (depth0 != null ? lookupProperty(depth0, "current_id") : depth0)) != null ? helper : alias2), (typeof helper === alias3 ? helper.call(alias1, {
          "name": "current_id",
          "hash": {},
          "data": data,
          "loc": {"start": {"line": 5, "column": 18}, "end": {"line": 5, "column": 32}}
        }) : helper)))
        + "</b><br>\n        <ul class=\"list-unstyled\">\n"
        + ((stack1 = lookupProperty(helpers, "each").call(alias1, (depth0 != null ? lookupProperty(depth0, "values") : depth0), {
          "name": "each",
          "hash": {},
          "fn": container.program(1, data, 0),
          "inverse": container.noop,
          "data": data,
          "loc": {"start": {"line": 7, "column": 12}, "end": {"line": 9, "column": 21}}
        })) != null ? stack1 : "")
        + "        </ul>\n        <a class = \"moreinfo\" data-record-id=\""
        + alias4(((helper = (helper = lookupProperty(helpers, "current_id") || (depth0 != null ? lookupProperty(depth0, "current_id") : depth0)) != null ? helper : alias2), (typeof helper === alias3 ? helper.call(alias1, {
          "name": "current_id",
          "hash": {},
          "data": data,
          "loc": {"start": {"line": 11, "column": 46}, "end": {"line": 11, "column": 60}}
        }) : helper)))
        + "\">Read more</a> |\n        <a href=\"/edit/"
        + alias4(((helper = (helper = lookupProperty(helpers, "current_id") || (depth0 != null ? lookupProperty(depth0, "current_id") : depth0)) != null ? helper : alias2), (typeof helper === alias3 ? helper.call(alias1, {
          "name": "current_id",
          "hash": {},
          "data": data,
          "loc": {"start": {"line": 12, "column": 23}, "end": {"line": 12, "column": 37}}
        }) : helper)))
        + "\">Edit item</a>\n    </div>'\n    data-tippy-animation=\"scale\"\n    data-tippy-duration=\"0\"\n    data-tippy-followCursor=\"initial\"\n    data-tippy-arrow=\"true\"\n    data-tippy-delay=\"[200, 200]\"\n  >\n  "
        + alias4(((helper = (helper = lookupProperty(helpers, "content") || (depth0 != null ? lookupProperty(depth0, "content") : depth0)) != null ? helper : alias2), (typeof helper === alias3 ? helper.call(alias1, {
          "name": "content",
          "hash": {},
          "data": data,
          "loc": {"start": {"line": 20, "column": 2}, "end": {"line": 20, "column": 13}}
        }) : helper)))
        + "\n</div>\n";
    }, "useData": true
  });
})();
