import { Component } from "component";
import { getFieldValues } from "get-field-values";

class DependentFieldsComponent extends Component {
  constructor(element)  {
    super(element);
    this.initDependentFields();
  }

  initDependentFields() {
    const field = this.getFieldDependency();
    this.setupDependentField(field);
  }

  getFieldDependency() {
    const dependency = $(this.element).data("dependency");
    const decoded = JSON.parse(atob(dependency));
    const rules = decoded.rules;
    const condition = decoded.condition;

    const rr = jQuery.map(rules, function(rule) {
      const match_type = rule.operator;
      const is_negative = match_type.indexOf("not") !== -1 ? true : false;
      const regexp =
        match_type.indexOf("equal") !== -1
          ? new RegExp("^" + rule.value + "$", "i")
          : new RegExp(rule.value, "i");
          let id = rule.id;
          let filtered = false;
      if (rule.filtered) { // Whether the field is of type "filval"
        id = rule.filtered;
        filtered = true;
      }
      return {
        dependsOn: $(`[data-column-id="${id}"]`),
        regexp: regexp,
        is_negative: is_negative,
        filtered: filtered
      };
    });

    return {
      field: $(this.element),
      condition: condition,
      rules: rr
    };
  }

  /***
   *
   * Handle the dependency connections between fields
   * via regular expression checks on field values
   *
   * FIXME: It would be an improvement to abstract the
   * different field types in GADS behind a common interface
   * as opposed to using dom-attributes.
   *
  */
  setupDependentField(field) {
    const condition = field.condition;
    const rules = field.rules;
    const $field = field.field;
    // In order to hide the relevant fields, we used to trigger a change event
    // on all the fields they depended on. However, this doesn't work for
    // display fields that depend on a filval type field, as the values to
    // check are not rendered on the page until the relevant filtered curval
    // field is opened. As such, use the dependent-not-shown property instead,
    // which is evaluated server-side
    if ($field.data("dependent-not-shown")) {
      $field.hide();
    }

    const test_all = function(condition, rules) {
      if (rules.length == 0) {
        return true;
      }

      let is_shown = false;

      rules.some(function(rule) {
        // Break if returns true

        const $depends = rule.dependsOn;
        const regexp = rule.regexp;
        const is_negative = rule.is_negative;
        const values = getFieldValues($depends, rule.filtered);
        let this_not_shown = is_negative ? false : true;
        $.each(values, function(index, value) {
          // Blank values are returned as undefined for consistency with
          // backend calc code. Convert to empty string, otherwise they will
          // be rendered as the string "undefined" in a regex
          if (value === undefined) value = "";
          if (is_negative) {
            if (regexp.test(value)) this_not_shown = 1;
          } else {
            if (regexp.test(value)) this_not_shown = 0;
          }
        });

        if (!this_not_shown) {
          is_shown = true;
        }

        if (condition) {
          if (condition == "OR") {
            return is_shown; // Whether to break
          }
          if (this_not_shown) {
            is_shown = false;
          }
          return !is_shown; // Whether to break
        }

        return false; // Continue loop
      });

      return is_shown;
    };

    rules.forEach(function(rule) {
      const $depends = rule.dependsOn;

      const processChange = function() {
        test_all(condition, rules) ? $field.show() : $field.hide();
        const $expandableCard = $field.closest(".card--expandable");

        if ($expandableCard.length) {
          // Check each field in the card to see if none are shown, and
          // hide/show the card accordingly
          let none_shown = true; // Assume card not shown
          $expandableCard.find(".linkspace-field").each(function() {
            if ($(this).css("display") != "none") {
              none_shown = false;
              return; // Shortcut checking any more fields
            }
          });
          const $collapsibleElm = $expandableCard.find(".collapse");
          if (none_shown) {
            $collapsibleElm.closest(".card").hide();
          } else {
            $collapsibleElm.closest(".card").show();
          }
        }

        // Trigger value check on any fields that depend on this one, e.g.
        // if this one is now hidden then that will change its value to
        // blank. Don't do this if the dependent field is the same as the field
        // with the display condition.
        if ($field.data("column-id") != $depends.data("column-id"))
            $field.trigger("change");
      };

      // If the field depended on is not actually in the form (e.g. if the
      // user doesn't have access to it) then treat it as an empty value and
      // process as normal. Process immediately as the value won't change
      if ($depends.length == 0) {
        processChange();
      }

      // Standard change of visible form field
      $depends.on("change", function() {
          processChange();
      });
    });
  }
}

export default DependentFieldsComponent;
