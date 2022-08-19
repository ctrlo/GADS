const setupSelectWidgets = (() => {
  /*
   * A SelectWidget is a custom disclosure widget
   * with multi or single options selectable.
   * SelectWidgets can depend on each other;
   * for instance if Value "1" is selected in Widget "A",
   * Widget "B" might not be displayed.
   */
  var SelectWidget = function(multi) {
    var $selectWidget = this;
    var $widget = this.find(".form-control");
    var $trigger = $widget.find("[aria-expanded]");
    var $current = this.find(".current");
    var $available = this.find(".available");
    var $availableItems = this.find(".available .answer input");
    var $moreInfoButtons = this.find(".available .answer .more-info");
    var $target = this.find("#" + $trigger.attr("aria-controls"));
    var $currentItems = $current.find("[data-list-item]");
    var $answers = this.find(".answer");
    var $fakeInput = null;
    var $search = this.find(".form-control-search");
    var lastFetchParams = null;

    var collapse = function($widget, $trigger, $target) {
      $selectWidget.removeClass("select-widget--open");
      $trigger.attr("aria-expanded", false);

      // Add a small delay when hiding the select widget, to allow IE to also
      // fire the default actions when selecting a radio button by clicking on
      // its label. When the input is hidden on the click event of the label
      // the input isn't actually being selected.
      setTimeout(function() {
        $search.val("");
        $target.attr("hidden", "");
        $answers.removeAttr("hidden");
      }, 50);
    };

    var updateState = function(no_trigger_change) {
      var $visible = $current.children("[data-list-item]:not([hidden])");

      $current.toggleClass("empty", $visible.length === 0);
      if (!no_trigger_change)
        $widget.trigger("change");
    };

    var possibleCloseWidget = function(e) {
      var newlyFocussedElement = e.relatedTarget || document.activeElement;
      if (
        !$selectWidget.find(newlyFocussedElement).length &&
        newlyFocussedElement &&
        !$(newlyFocussedElement).is(".modal, .page") &&
        $selectWidget.get(0).parentNode !== newlyFocussedElement
      ) {
        collapse($widget, $trigger, $target);
      }
    };

    var connectMulti = function(update) {
      return function() {
        var $item = $(this);
        var itemId = $item.data("list-item");
        var $associated = $("#" + itemId);
        $associated.unbind("change");
        $associated.on("change", function(e) {
          e.stopPropagation();
          if ($(this).prop("checked")) {
            $item.removeAttr("hidden");
          } else {
            $item.attr("hidden", "");
          }
          update();
        });

        $associated.unbind("keydown");
        $associated.on("keydown", function(e) {
          var key = e.which || e.keyCode;
          switch (key) {
            case 38: // UP
            case 40: // DOWN
              var answers = $available.find(".answer:not([hidden])");
              var currentIndex = answers.index($associated.closest(".answer"));
              var nextItem;

              e.preventDefault();

              if (key === 38) {
                nextItem = answers[currentIndex - 1];
              } else {
                nextItem = answers[currentIndex + 1];
              }

              if (nextItem) {
                $(nextItem)
                  .find("input")
                  .focus();
              }

              break;
            case 13:
              e.preventDefault();
              $(this).trigger("click");
              break;
          }
        });
      };
    };

    var connectSingle = function() {
      $currentItems.each(function(_, item) {
        var $item = $(item);
        var itemId = $item.data("list-item");
        var $associated = $("#" + itemId);

        $associated.unbind("click");
        $associated.on("click", function(e) {
          e.stopPropagation();
        });

        $associated.parent().unbind("keypress");
        $associated.parent().on("keypress", function(e) {
          // KeyCode Enter or Spacebar
          if (e.keyCode === 13 || e.keyCode === 32) {
            e.preventDefault();
            $(this).trigger("click");
          }
        });

        $associated.parent().unbind("click");
        $associated.parent().on("click", function(e) {
          e.stopPropagation();
          $currentItems.each(function() {
            $(this).attr("hidden", "");
          });

          $current.toggleClass("empty", false);
          $item.removeAttr("hidden");

          collapse($widget, $trigger, $target);
        });
      });
    };

    var connect = function() {
      if (multi) {
        $currentItems.each(connectMulti(updateState));
      } else {
        connectSingle();
      }
    };

    var currentLi = function(multi, field, value, label, checked, html) {
      if (multi && !value) {
        return $('<li class="none-selected">blank</li>');
      }

      var valueId = value ? field + "_" + value : field + "__blank";
      var className = value ? "" : "current__blank";
      var deleteButton = multi
        ? '<button type="button" class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>'
        : "";
      var $li = $(
        "<li " +
          (checked ? "" : "hidden") +
          ' data-list-item="' +
          valueId +
          '" class="' +
          className +
          '"><span class="widget-value__value">' +
          "</span>" +
          deleteButton +
          "</li>"
      );
      $li.data('list-text', label);
      $li.find('span').html(html);
      return $li;
    };

    var availableLi = function(multi, field, value, label, checked, html) {
      if (multi && !value) {
        return null;
      }

      var valueId = value ? field + "_" + value : field + "__blank";
      var classNames = value ? "answer" : "answer answer--blank";

      // Add space at beginning to keep format consistent with that in template
      var detailsButton =
        ' <span class="details">' +
        '<button type="button" class="more-info" data-record-id="' +
        value +
        '" aria-describedby="' +
        valueId +
        '_label" aria-haspopup="listbox">' +
        "Details" +
        "</button>" +
        "</span>";

      var $span = $('<span role="option"></span>');
      $span.data('list-text', label);
      $span.data('list-id', value);
      $span.html(html);
      var $li = $(
        '<li class="' +
          classNames +
          '">' +
          '<span class="control">' +
          '<label id="' +
          valueId +
          '_label" for="' +
          valueId +
          '">' +
          '<input id="' +
          valueId +
          '" type="' +
          (multi ? "checkbox" : "radio") +
          '" name="' +
          field +
          '" ' +
          (checked ? "checked" : "") +
          ' value="' +
          (value || "") +
          '" class="' +
          (multi ? "" : "visually-hidden") +
          '" aria-labelledby="' +
          valueId +
          '_label"> ' + // Add space to keep spacing consistent with templates
          "</label>" +
          "</span>" +
          (value ? detailsButton : "") +
          "</li>"
      );
      $li.find('label').append($span);
      return $li;
    };

    // Give each AJAX load its own ID. If a higher ID has started by the time
    // we get the results, then cancel the current process to prevent
    // duplicate items being added to the dropdown
    var loadCounter = 0;

    var updateJson = function(url, typeahead) {
      loadCounter++;
      var myLoad = loadCounter; // ID of this process
      $available.find(".spinner").removeAttr("hidden");
      var currentValues = $available
        .find("input:checked")
        .map(function() {
          return parseInt($(this).val());
        })
        .get();

      // Remove existing items if needed, now that we have found out which ones
      // are selected
      if (!typeahead)
          $available.find(".answer").remove();

      var field = $selectWidget.data("field");
      // If we cancel this particular loop, then we don't want to remove the
      // spinner if another one has since started running
      var hideSpinner = true;
      $.getJSON(url, function(data) {
        if (data.error === 0) {
          if (myLoad != loadCounter) { // A new one has started running
            hideSpinner = false; // Don't remove the spinner on completion
            return;
          }
          if (typeahead) {
            // Need to keep currently selected item
            $currentItems.filter(':hidden').remove();
          } else {
            $currentItems.remove();
          }

          var checked = currentValues.includes(NaN);
          if (multi) {
            $search
              .parent()
              .prevAll(".none-selected")
              .remove(); // Prevent duplicate blank entries
            $search
              .parent()
              .before(currentLi(multi, field, null, "blank", checked));
            $available.append(availableLi(multi, field, null, "blank", checked));
          }

          $.each(data.records, function(recordIndex, record) {
            var checked = currentValues.includes(record.id);
            if (!typeahead || (typeahead && !checked)) {
              $search
                .parent()
                .before(
                  currentLi(multi, field, record.id, record.label, checked, record.html)
                ).before(' '); // Ensure space between elements
              $available.append(
                availableLi(multi, field, record.id, record.label, checked, record.html)
              );
            }
          });

          $currentItems = $current.find("[data-list-item]");
          $available = $selectWidget.find(".available");
          $availableItems = $selectWidget.find(".available .answer input");
          $moreInfoButtons = $selectWidget.find(
            ".available .answer .more-info"
          );
          $answers = $selectWidget.find(".answer");

          updateState();
          connect();

          $availableItems.on("blur", possibleCloseWidget);
          $moreInfoButtons.on("blur", possibleCloseWidget);

        } else {
          var errorMessage =
            data.error === 1 ? data.message : "Oops! Something went wrong.";
          var errorLi = $(
            '<li class="answer answer--blank alert alert-danger"><span class="control"><label>' +
              errorMessage +
              "</label></span></li>"
          );
          $available.append(errorLi);
        }
      })
        .fail(function(jqXHR, textStatus, textError) {
          var errorMessage = "Oops! Something went wrong.";
          Linkspace.error(
            "Failed to make request to " +
              filterEndpoint +
              ": " +
              textStatus +
              ": " +
              textError
          );
          var errorLi = $(
            '<li class="answer answer--blank alert alert-danger"><span class="control"><label>' +
              errorMessage +
              "</label></span></li>"
          );
          $available.append(errorLi);
        })
        .always(function() {
          if (hideSpinner) {
            $available.find(".spinner").attr("hidden", "");
          }
        });
    };

    var fetchOptions = function() {
      var field = $selectWidget.data("field");
      var multi = $selectWidget.hasClass("multi");
      var filterEndpoint = $selectWidget.data("filter-endpoint");
      var filterFields = $selectWidget.data("filter-fields");
      var submissionToken = $selectWidget.data("submission-token");
      if (!$.isArray(filterFields)) {
        Linkspace.error(
          "Invalid data-filter-fields found. It should be a proper JSON array of fields."
        );
      }

      // Collect values of linked fields
      var values = ["submission-token=" + submissionToken];
      $.each(filterFields, function(_, field) {
        $("input[name=" + field + "]").each(function(_, input) {
          var $input = $(input);
          switch ($input.attr("type")) {
            case "text":
              values.push(field + "=" + $input.val());
              break;
            case "radio":
              if (input.checked) {
                values.push(field + "=" + $input.val());
              }
              break;
            case "checkbox":
              if (input.checked) {
                values.push(field + "=" + $input.val());
              }
              break;
            case "hidden": // Tree values stored as hidden field
              values.push(field + "=" + $input.val());
              break;
          }
        });
      });

      // Bail out if the options haven't changed
      var fetchParams = values.join("&");
      if (lastFetchParams === fetchParams) {
        return;
      }
      lastFetchParams = null;

      updateJson(filterEndpoint + "?" + fetchParams);
      lastFetchParams = fetchParams;

    };

    var expand = function($widget, $trigger, $target) {
      if ($trigger.attr("aria-expanded") === "true") {
        return;
      }

      $selectWidget.addClass("select-widget--open");
      $trigger.attr("aria-expanded", true);

      if (
        $selectWidget.data("filter-endpoint") &&
        $selectWidget.data("filter-endpoint").length
      ) {
        fetchOptions();
      }

      var widgetTop = $widget.offset().top;
      var widgetBottom = widgetTop + $widget.outerHeight();
      var viewportTop = $(window).scrollTop();
      var viewportBottom = viewportTop + $(window).height() - 60;
      var minimumRequiredSpace = 200;
      var fitsBelow = widgetBottom + minimumRequiredSpace < viewportBottom;
      var fitsAbove = widgetTop - minimumRequiredSpace > viewportTop;
      var expandAtTop = fitsAbove && !fitsBelow;
      $target.toggleClass("available--top", expandAtTop);
      $target.removeAttr("hidden");

      if ($search.get(0) !== document.activeElement) {
        $search.focus();
      }
    };

    updateState(true);

    connect();

    $widget.unbind("click");
    $widget.on("click", function() {
      if ($trigger.attr("aria-expanded") === "true") {
        collapse($widget, $trigger, $target);
      } else {
        expand($widget, $trigger, $target);
      }
    });

    $search.unbind("blur");
    $search.on("blur", possibleCloseWidget);

    $availableItems.unbind("blur");
    $availableItems.on("blur", possibleCloseWidget);

    $moreInfoButtons.unbind("blur");
    $moreInfoButtons.on("blur", possibleCloseWidget);

    $(document).on(
      "click",
      function(e) {
        var clickedOutside =
          !this.is(e.target) && this.has(e.target).length === 0;
        var clickedInDialog = $(e.target).closest(".modal").length !== 0;
        if (clickedOutside && !clickedInDialog) {
          collapse($widget, $trigger, $target);
        }
      }.bind(this)
    );

    $(document).keyup(function(e) {
      if (e.keyCode == 27) {
        collapse($widget, $trigger, $target);
      }
    });

    var expandWidgetHandler = function(e) {
      e.stopPropagation();
      expand($widget, $trigger, $target);
    };

    $widget.delegate(".select-widget-value__delete", "click", function(e) {
      e.preventDefault();
      e.stopPropagation();

      // Uncheck checkbox
      var checkboxId = e.target.parentElement.getAttribute("data-list-item");
      var checkbox = document.querySelector("#" + checkboxId);
      checkbox.checked = false;
      $(checkbox).trigger("change");
    });

    $search.unbind("focus", expandWidgetHandler);
    $search.on("focus", expandWidgetHandler);

    $search.unbind("keydown");
    $search.on("keydown", function(e) {
      var key = e.which || e.keyCode;
      switch (key) {
        case 38: // UP
        case 40: // DOWN
          var items = $available.find(".answer:not([hidden]) input");
          var nextItem;

          e.preventDefault();

          if (key === 38) {
            nextItem = items[items.length - 1];
          } else {
            nextItem = items[0];
          }

          if (nextItem) {
            $(nextItem).focus();
          }

          break;
        case 13: // ENTER
          e.preventDefault();

          // Select the first (visible) item
          var firstItem = $available.find(".answer:not([hidden]) input").get(0);
          if (firstItem) {
            $(firstItem)
              .parent()
              .trigger("click");
          }

          break;
      }
    });

    $search.unbind("keyup");
    var timeout;
    $search.on("keyup", function() {
      var searchValue = $(this)
        .val()
        .toLowerCase();

      $fakeInput =
        $fakeInput ||
        $("<span>")
          .addClass("form-control-search")
          .css("white-space", "nowrap");
      $fakeInput.text(searchValue);
      $search.css("width", $fakeInput.insertAfter($search).width() + 70);
      $fakeInput.detach();

      if ($selectWidget.data("value-selector") == "typeahead") {
        var url = `/${$selectWidget.data(
          "layout-id"
        )}/match/layout/${$selectWidget.data("typeahead-id")}`;
        // Debounce the user input, only execute after 200ms if another one
        // hasn't started
        clearTimeout(timeout);
        $available.find(".spinner").removeAttr("hidden");
        timeout = setTimeout(function() {
          $available.find(".answer").not('.answer--blank').each(function() {
            var $answer = $(this);
            if (!$answer.find('input:checked').length) {
              $answer.remove();
            }
          });
          updateJson(url + '?noempty=1&q=' + searchValue, true);
        }, 200);
      } else {
        // hide the answers that do not contain the searchvalue
        var anyHits = false;
        $.each($answers, function() {
          var labelValue = $(this)
            .find("label")[0]
            .innerHTML.toLowerCase();
          if (labelValue.indexOf(searchValue) === -1) {
            $(this).attr("hidden", "");
          } else {
            anyHits = true;
            $(this).removeAttr("hidden", "");
          }
        });

        if (anyHits) {
          $available.find(".has-noresults").attr("hidden", "");
        } else {
          $available.find(".has-noresults").removeAttr("hidden", "");
        }
      }
    });

    $search.unbind("click");
    $search.on("click", function(e) {
      // Prevent bubbling the click event to the $widget (which expands/collapses the widget on click).
      e.stopPropagation();
    });
  };

  var init = function(context) {
    var $nodes = $(".select-widget", context);
    $nodes.each(function() {
      var multi = $(this).hasClass("multi");
      SelectWidget.call($(this), multi);
    });
  };

  return context => {
    init(context);
  };
})();

export { setupSelectWidgets };
