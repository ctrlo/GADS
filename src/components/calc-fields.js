import { getFieldValues } from "../lib/get-field-values";

const setupCalcFields = (() => {

  var setupCalcField = function() {
    var code = this.code;
    var depends_on = this.depends_on;
    var $field = this.field;
    var params = this.params;

    // Change standard backend code format to a format that works for
    // evaluating in the browser
    var re = /^function\s+evaluate\s+/gi;
    code = code.replace(re, "function ");
    code = "return " + code;

    depends_on.forEach(function($depend_on) {

      // Standard change of visible form field that this calc depends on.  When
      // it changes get all the values this code depends on and evaluate the
      // code
      $depend_on.on("change", function() {

        // All the values
        var vars = params.map(function(value) {
          var $depends = $('.linkspace-field[data-name-short="'+value+'"]');
          return getFieldValues($depends, false, true);
        });

        // Evaluate the code with the values
        var func = fengari.load(code)();
        var first = vars.shift();
        // Use apply() to be able to pass the params as a single array. The
        // first needs to be passed separately so shift it off and do so
        var returnval = func.apply(first, vars);

        // Update the field holding the code's value
        $field.find('input').val(returnval);
        // And trigger a change on its parent div to trigger any display
        // conditions
        $field.closest('.linkspace-field').trigger("change");
      });
    });
  };

  var setupCalcFields = function(context) {
    var fields = $("[data-calc-depends-on]", context).map(function() {
      var dependency = $(this).data("calc-depends-on");
      var depends_on_ids = JSON.parse(base64.decode(dependency));

      var depends_on = jQuery.map(depends_on_ids, function(id) {
        return $('[data-column-id="' + id + '"]', context);
      });

      return {
        field: $(this),
        code: base64.decode($(this).data("code")),
        params: JSON.parse(base64.decode($(this).data("code-params"))),
        depends_on: depends_on
      };
    });

    fields.each(setupCalcField);
  };

  return context => {
    setupCalcFields(context);
  };
})();

export { setupCalcFields };
