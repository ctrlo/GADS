import {Component} from 'component'
import {getFieldValues} from "get-field-values"

class CalcFieldsComponent extends Component {
  constructor(element) {
    super(element)
    this.initCalcFields()
  }

  initCalcFields() {
    const field = this.getFieldCalc();
    this.setupCalcField(field);
  }

  getFieldCalc() {

    const dependency = $(this.element).data("calc-depends-on")
    const depends_on_ids = JSON.parse(atob(dependency))
    const depends_on = jQuery.map(depends_on_ids, function (id) {
      return $('[data-column-id="' + id + '"]')
    });

    return {
      field: $(this.element),
      code: atob($(this.element).data("code")).toString(),
      params: JSON.parse(atob($(this.element).data("code-params"))),
      depends_on: depends_on
    };

  }

  setupCalcField(field) {
    let {code} = field
    const {depends_on, params} = field
    const $field = field.field

    // Change standard backend code format to a format that works for
    // evaluating in the browser
    const re = /^function\s+evaluate\s+/gi;
    code = code.replace(re, "function ")
    code = "return " + code

    depends_on.forEach(function ($depend_on) {

      // Standard change of visible form field that this calc depends on.  When
      // it changes get all the values this code depends on and evaluate the
      // code
      $depend_on.on("change", function () {

        // All the values
        const vars = params.map(function (value) {
          const $depends = $('.linkspace-field[data-name-short="' + value + '"]');
          let ret = getFieldValues($depends, false, true)
          // If an array is passed in as-is, then its first element will be at
          // array index 0, which ipairs will not recognize. Therefore,
          // offset all the elements into an object starting at index 1
          if (Array.isArray(ret)) {
            let ret2 = []
            ret.forEach((element, index) => ret2[index + 1] = element)
            ret = ret2
          }
          return ret
        });

        // Evaluate the code with the values
        // eslint-disable-next-line no-undef
        const func = fengari.load(code)();
        const first = vars.shift();
        // Use apply() to be able to pass the params as a single array. The
        // first needs to be passed separately so shift it off and do so
        const returnval = func.apply(first, vars);

        // Update the field holding the code's value
        $field.find('textarea').val(returnval)
        // And trigger a change on its parent div to trigger any display
        // conditions
        $field.closest('.linkspace-field').trigger("change")
        $field.find('textarea').trigger('change');
      });
    });
  }
}

export default CalcFieldsComponent
