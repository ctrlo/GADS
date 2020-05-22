const setupColumnFilters = (() => {
  var getParams = function(options) {
    if (!options) { options = {} }; // IE11 compat
    return _.chain(location.search.slice(1).split('&'))
        .map(function (item) { if (item) { return item.split('='); } })
        .compact()
        .value()
        .filter(function(param) { return param[0] !== options.except});
  }

  var setupColumnFilters = function(context) {
    $(".column-filter", context).each(function() {
        var $columnFilter =  $(this);
        var colId =  $columnFilter.data("col-id");
        var autocompleteEndpoint = $columnFilter.data("autocomplete-endpoint");
        var autocompleteHasID = $columnFilter.data("autocomplete-has-id");
        var values = $columnFilter.data("values") || [];
        var $error = $columnFilter.find(".column-filter__error");
        var $searchInput = $columnFilter.find(".column-filter__search-input");
        var $clearSearchInput = $columnFilter.find(".column-filter__clear-search-input");
        var $spinner = $columnFilter.find(".column-filter__spinner");
        var $values = $columnFilter.find(".column-filter__values");
        var $submit = $columnFilter.find(".column-filter__submit");

        var searchQ = function() {
            return $searchInput.length ? $searchInput.val() : "";
        }

        var onEmptySearch = function() {
            $error.attr('hidden', '');
            renderValues();
        }

        var fetchValues = _.debounce(function() {
            var q = searchQ();
            if (!q.length) {
                onEmptySearch();
                return;
            }

            $error.attr('hidden', '');
            $spinner.removeAttr('hidden');

            $.getJSON(autocompleteEndpoint + q, function(data) {
                _.each(data, function(searchValue) {
                    if (autocompleteHasID) {
                        if (!_.some(values, function(value) {return value.id === searchValue.id.toString()})) {
                            values.push({
                                id: searchValue.id.toString(),
                                value: searchValue.name
                            });
                        }
                    } else {
                        values.push({ value: searchValue });
                    }
                });
            })
            .fail(function(jqXHR, textStatus, textError) {
                $error.text(textError);
                $error.removeAttr('hidden');
            })
            .always(function() {
                $spinner.attr('hidden', '');
                renderValues();
            });
        }, 250);

        // Values are sorted when we've got a search input field, so additional values
        // received from the API are sorted amongst currently available values.
        var sortValues = function() {
            return $searchInput.length === 1;
        }

        var renderValues = function() {
            var q = searchQ();
            $values.empty();
            var filteredValues = _.filter(values, function(value) {return value.value.toLowerCase().indexOf(q.toLowerCase()) > -1});
            var sortedAndFilteredValues = sortValues() ? _.sortBy(filteredValues, "value") : filteredValues;
            _.each(sortedAndFilteredValues, function(value, index) {
               $values.append(renderValue(value, index));
            });
        }

        var renderValue = function(value, index) {
            var uniquePrefix = 'column_filter_value_label_' + colId + '_' + index;
            return $('<li class="column-filter__value">' +
                '<label id="' + uniquePrefix + '_label" for="' + uniquePrefix + '">' +
                    '<input id="' + uniquePrefix + '" type="checkbox" value="' + value.id + '" ' + (value.checked ? "checked" : "") + ' aria-labelledby="' + uniquePrefix + '_label">' +
                    '<span role="option">' + value.value + '</span>' +
                '</label>' +
            '</li>');
        }

        $values.delegate("input", "change", function() {
            var checkboxValue = $(this).val();
            var valueIndex = _.findIndex(values, function(value) {return value.id === checkboxValue});
            values[valueIndex].checked = this.checked;
        });

        $searchInput.on("keyup", function() {
            var val = $(this).val();
            if (val.length) {
                $clearSearchInput.removeAttr('hidden');
            } else {
                $clearSearchInput.attr('hidden', '');
            }
        });

        var paramfull = function (param) {
            if (typeof param[1] === 'undefined') {
                return param[0];
            } else {
                return param[0] + "=" + param[1];
            }
        };
        if (autocompleteHasID) {
            $searchInput.on("keyup", fetchValues);

            $submit.on("click", function() {
                var selectedValues = _.map(_.filter(values, "checked"), "id");
                var params = getParams({except: "field" + colId});
                selectedValues.forEach(function(value) {
                    params.push(["field" + colId, value]);
                });
                window.location = "?" + params.map(function(param) { return paramfull(param); }).join("&");
            });
        } else {
            $searchInput.on('keypress', function(e) {
                // KeyCode Enter
                if (e.keyCode === 13) {
                    e.preventDefault();
                    $submit.trigger('click');
                }
            })

            $submit.on("click", function() {
                var params = getParams({except: "field" + colId});
                params.push(["field" + colId, searchQ()]);
                window.location = "?" + params.map(function(param) { return paramfull(param); }).join("&");
            });
        }

        $clearSearchInput.on("click", function(e) {
            e.preventDefault();
            $searchInput.val("");
            $clearSearchInput.attr('hidden', '');
            onEmptySearch();
        });

        renderValues();
    });
  }

  return context => {
    setupColumnFilters(context);
  };
})()

export { setupColumnFilters };
