(function() {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
templates['timelineitem'] = template({"1":function(container,depth0,helpers,partials,data) {
    var stack1, helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=helpers.helperMissing, alias3="function";

  return "                <li>"
    + container.escapeExpression(((helper = (helper = helpers.name || (depth0 != null ? depth0.name : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"name","hash":{},"data":data}) : helper)))
    + ": "
    + ((stack1 = ((helper = (helper = helpers.value || (depth0 != null ? depth0.value : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"value","hash":{},"data":data}) : helper))) != null ? stack1 : "")
    + "</li>\n";
},"compiler":[7,">= 4.0.0"],"main":function(container,depth0,helpers,partials,data) {
    var stack1, helper, alias1=depth0 != null ? depth0 : (container.nullContext || {}), alias2=helpers.helperMissing, alias3="function", alias4=container.escapeExpression;

  return "<div class=\"timeline-tippy\"\n    data-tippy-sticky=\"true\"\n    data-tippy-interactive=\"true\"\n    data-tippy-content='<div>\n        <b>Record "
    + alias4(((helper = (helper = helpers.current_id || (depth0 != null ? depth0.current_id : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"current_id","hash":{},"data":data}) : helper)))
    + "</b><br>\n        <ul class=\"list-unstyled\">\n"
    + ((stack1 = helpers.each.call(alias1,(depth0 != null ? depth0.values : depth0),{"name":"each","hash":{},"fn":container.program(1, data, 0),"inverse":container.noop,"data":data})) != null ? stack1 : "")
    + "        </ul>\n        <a class = \"moreinfo\" data-record-id=\""
    + alias4(((helper = (helper = helpers.current_id || (depth0 != null ? depth0.current_id : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"current_id","hash":{},"data":data}) : helper)))
    + "\">Read more</a> |\n        <a href=\"/edit/"
    + alias4(((helper = (helper = helpers.current_id || (depth0 != null ? depth0.current_id : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"current_id","hash":{},"data":data}) : helper)))
    + "\">Edit item</a>\n    </div>'\n    data-tippy-animation=\"scale\"\n    data-tippy-duration=\"0\"\n    data-tippy-followCursor=\"initial\"\n    data-tippy-arrow=\"true\"\n    data-tippy-delay=\"[200, 200]\"\n  >\n  "
    + alias4(((helper = (helper = helpers.content || (depth0 != null ? depth0.content : depth0)) != null ? helper : alias2),(typeof helper === alias3 ? helper.call(alias1,{"name":"content","hash":{},"data":data}) : helper)))
    + "\n</div>\n";
},"useData":true});
})();