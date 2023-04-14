import { Component } from 'component'
import { getFieldValues } from "get-field-values"

class CalcFieldsComponent extends Component {
  constructor(element)  {
    super(element)
    this.initCalcFields()
  }

  initCalcFields() {
    const field = this.getFieldCalc();
    this.setupCalcField(field);
  }

  getFieldCalc() {

      const dependency = $(this.element).data("calc-depends-on")
      const depends_on_ids = JSON.parse(Buffer.from(dependency, 'base64'))
      const depends_on = jQuery.map(depends_on_ids, function(id) {
        return $('[data-column-id="' + id + '"]')
      });

      return {
        field: $(this.element),
        code: Buffer.from($(this.element).data("code"), 'base64').toString(),
        params: JSON.parse(Buffer.from($(this.element).data("code-params"), 'base64')),
        depends_on: depends_on
      };

  }

  setupCalcField(field) {
    let code = field.code
    const depends_on = field.depends_on
    const $field = field.field
    const params = field.params

    // Change standard backend code format to a format that works for
    // evaluating in the browser
    var re = /^function\s+evaluate\s+/gi
    code = code.replace(re, "function ")
    code = "return " + code

    depends_on.forEach(function($depend_on) {

      // Standard change of visible form field that this calc depends on.  When
      // it changes get all the values this code depends on and evaluate the
      // code
      $depend_on.on("change", function() {

        // All the values
        var vars = params.map(function(value) {
          var $depends = $('.linkspace-field[data-name-short="'+value+'"]')
          return getFieldValues($depends, false, true)
        });

        // Evaluate the code with the values
        var func = fengari.load(code)()
        var first = vars.shift()
        // Use apply() to be able to pass the params as a single array. The
        // first needs to be passed separately so shift it off and do so
        var returnval = func.apply(first, vars)

        // Update the field holding the code's value
        $field.find('input').val(returnval)
        // And trigger a change on its parent div to trigger any display
        // conditions
        $field.closest('.linkspace-field').trigger("change")
      });
    });
  }
}

export default CalcFieldsComponent
