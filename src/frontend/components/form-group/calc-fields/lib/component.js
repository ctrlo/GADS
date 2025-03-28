import { Component } from 'component'
import { getFieldValues } from "get-field-values"

/**
 * Calc Fields Component
 */
class CalcFieldsComponent extends Component {
  /**
   * Create a new Calc Fields Component
   * @param {HTMLElement} element The field that is a calc field
   */
  constructor(element) {
    super(element)
    this.initCalcFields()
  }

  /**
   * Initialize the calc fields component
   */
  initCalcFields() {
    const field = this.getFieldCalc();
    this.setupCalcField(field);
  }

  /**
   * Get the calc field data
   * @returns {Object} The field, it's code, and it's dependencies
   */
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

  /**
   * Set up the calc field
   * @param {*} field The field to set up
   */
  setupCalcField(field) {
    let { code } = field
    const { depends_on, params } = field
    const $field = field.field

    // Change standard backend code format to a format that works for
    // evaluating in the browser
    var re = /^function\s+evaluate\s+/gi
    code = code.replace(re, "function ")
    code = "return " + code

    depends_on.forEach(function ($depend_on) {

      // Standard change of visible form field that this calc depends on.  When
      // it changes get all the values this code depends on and evaluate the
      // code
      $depend_on.on("change", function () {

        // Recursively shift all the array fields in an object to start at index 1
        const shiftFields = (obj) => {
          // if obj is an array, shift all the elements into an object starting
          // at index 1
          if (Array.isArray(obj)) {
            // If an array is passed in as-is, then its first element will be at
            // array index 0, which ipairs will not recognise. Therefore,
            // offset all the elements into an object starting at index 1
            const obj2 = [];
            obj.forEach((element, index) => {
              obj2[index + 1] = element;
            });
            obj = obj2;
          } else {
            // If the field is an object, recursively shift its fields
            if (typeof obj === 'object') {
              for (const field in obj) {
                obj[field] = shiftFields(obj[field]);
              }
            }
          }
          return obj;
        }

        // All the values
        var vars = params.map(function (value) {
          var $depends = $('.linkspace-field[data-name-short="' + value + '"]')
          let ret = getFieldValues($depends, false, true)
          shiftFields(ret)

          return ret
        });

        // Evaluate the code with the values
        var func = fengari.load(code)()
        var first = vars.shift()
        // Use apply() to be able to pass the params as a single array. The
        // first needs to be passed separately so shift it off and do so
        var returnval = func.apply(first, vars)

        const $textArea = $field.find('textarea');
        // If the value in the textarea isn't the same as the return value, update it
        if ($textArea.val() != returnval) {
          // Update the field holding the code's value
          $textArea.val(returnval)
          // And trigger a change on its parent div to trigger any display
          // conditions
          $field.closest('.linkspace-field').trigger("change")
          $textArea.trigger('change');
        }
      });
    });
  }
}

export default CalcFieldsComponent
