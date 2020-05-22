const setupDependentFields = (() => {

  // get the value from a field, depending on its type
  var getFieldValues = function ($depends, filtered) {

    // If a field is not shown then treat it as a blank value (e.g. if fields
    // are in a hierarchy and the top one is not shown, or if the user does
    // not have write access to the field)
    if ($depends.length == 0 || $depends.css('display') == 'none') {
        return [''];
    }

    var type = $depends.data('column-type');

    var values = [];

    if (type === 'enum' || type === 'curval') {
        if (filtered) {
            var $visible = $depends.find('.select-widget .available .answer');
            $visible.each(function () {
                var item = $(this).find('[role="option"]');
                values.push(item.text());
            });
        } else {
            var $visible = $depends.find('.select-widget .current [data-list-item]:not([hidden])');
            $visible.each(function () {
                var item = $(this).hasClass("current__blank") ? "" : $(this).data('list-text');
                values.push(item)
            });
        }
    } else if (type === 'person') {
        values = [$depends.find('option:selected').text()];
    } else if (type === 'tree') {
        // get the hidden fields of the control - their textual value is located in a dat field
        $depends.find('.selected-tree-value').each(function() { values.push($(this).data('text-value')) });
    } else if (type === 'daterange') {
        var $f = $depends.find('.form-control');
        values = $f.map(function() {
            return $(this).val();
        }).get().join(' to ');
    } else {
        var $f = $depends.find('.form-control');
        values = [$f.val()];
    }

    // A multi-select field with no values selected should be the same as a
    // single-select with no values. Ensure that both are returned as a single
    // empty string value. This is important for display_condition testing, so
    // that at least one value is tested, even if it's empty
    if (values.length == 0) {
        values = [''];
    }

    return values;
  };

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
  var setupDependentField = function () {

    var condition = this.condition;
    var rules     = this.rules;
    var $field    = this.field;

    // In order to hide the relevant fields, we used to trigger a change event
    // on all the fields they depended on. However, this doesn't work for
    // display fields that depend on a filval type field, as the values to
    // check are not rendered on the page until the relevant filtered curval
    // field is opened. As such, use the dependent-not-shown property instead,
    // which is evaluated server-side
    if ($field.data('dependent-not-shown')) {
        $field.hide();
    }

    var some = function (set, test) {
        for (var i = 0, j = set.length; i < j; i++) {
            if (test(set[i])) {
                return true;
            }
        }
        return false;
    };

    var test_all = function (condition, rules) {

        if (rules.length == 0) {
            return true;
        }

        var is_shown = false;

        rules.some(function(rule) { // Break if returns true

            var $depends    = rule.dependsOn;
            var regexp      = rule.regexp;
            var is_negative = rule.is_negative;

            var values = getFieldValues($depends, rule.filtered);
            var this_not_shown = is_negative ? false : true;
            $.each(values, function (index, value) {
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
                if (condition == 'OR') {
                    return is_shown; // Whether to break
                } else {
                    if (this_not_shown) {
                        is_shown = false;
                    }
                    return !is_shown; // Whether to break
                }
            }

            return false; // Continue loop

        });

        return is_shown;

    };

    rules.forEach(function(rule) {

        var $depends    = rule.dependsOn;
        var regexp      = rule.regexp;
        var is_negative = rule.is_negative;

        var processChange = function () {
            test_all(condition, rules) ? $field.show() : $field.hide();
            var $panel = $field.closest('.panel-group');
            if ($panel.length) {
                $panel.find('.linkspace-field').each(function() {
                    var none_shown = true; // Assume not showing panel
                    if ($(this).css('display') != 'none') {
                        $panel.show();
                        none_shown = false;
                        return false; // Shortcut checking any more fields
                    }
                    if (none_shown) { $panel.hide() } // Nothing matched
                });
            }

            // Trigger value check on any fields that depend on this one, e.g.
            // if this one is now hidden then that will change its value to
            // blank
            $field.trigger('change');
        };

        // If the field depended on is not actually in the form (e.g. if the
        // user doesn't have access to it) then treat it as an empty value and
        // process as normal. Process immediately as the value won't change
        if ($depends.length == 0) {
            processChange();
        }

        // Standard change of visible form field
        $depends.on('change', function (e) {
            processChange();
        });
    });


  };

  var setupDependentFields = function (context) {
    var fields = $('[data-has-dependency]', context).map(function () {
        var dependency  = $(this).data('dependency');
        var decoded    = JSON.parse(base64.decode(dependency));
        var rules      = decoded.rules;
        var condition  = decoded.condition;

        var rr = jQuery.map(rules, function(rule) {
            var match_type  = rule.operator;
            var is_negative = match_type.indexOf('not') !== -1 ? true : false;
            var regexp = match_type.indexOf('equal') !== -1
                ? (new RegExp("^" + rule.value + "$", 'i'))
                : (new RegExp(rule.value, 'i'));
            var id = rule.id;
            var filtered = false;
            if (rule.filtered) {
                id = rule.filtered;
                filtered = true;
            }
            return {
                dependsOn   : $('[data-column-id="' + id + '"]', context),
                regexp      : regexp,
                is_negative : is_negative,
                filtered    : filtered
            };
        });

        return {
            field     : $(this),
            condition : condition,
            rules     : rr
        };
    });

    fields.each(setupDependentField);
  };

  return context => {
    setupDependentFields(context);
  };
})()

export { setupDependentFields };
