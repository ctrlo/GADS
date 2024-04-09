/* eslint-disable @typescript-eslint/no-this-alias */
import { Component } from 'component'
import { logging } from 'logging'
import { initValidationOnField } from 'validation'

  /*
   * A SelectWidget is a custom disclosure widget
   * with multi or single options selectable.
   * SelectWidgets can depend on each other;
   * for instance if Value "1" is selected in Widget "A",
   * Widget "B" might not be displayed.
   */
class SelectWidgetComponent extends Component {
  constructor(element)  {
    super(element)
    this.el = $(this.element)
    this.$selectWidget = this.el;
    this.$widget = this.el.find(".form-control");
    this.$trigger = this.$widget.find("[aria-expanded]");
    this.$current = this.el.find(".current");
    this.$available = this.el.find(".available");
    this.$availableItems = this.el.find(".available .answer input");
    this.$moreInfoButtons = this.el.find(".available .answer .btn-js-more-info");
    this.$target = this.el.find("#" + this.$trigger.attr("aria-controls"));
    this.$currentItems = this.$current.find("[data-list-item]");
    this.$answers = this.el.find(".answer");
    this.$fakeInput = null;
    this.$search = this.el.find(".form-control-search");
    this.lastFetchParams = null;
    this.multi = this.el.hasClass("multi")
    this.timeout
    this.required = this.el.hasClass("select-widget--required")
    // Give each AJAX load its own ID. If a higher ID has started by the time
    // we get the results, then cancel the current process to prevent
    // duplicate items being added to the dropdown
    this.loadCounter = 0

    this.initSelectWidget()

    if (this.required) {
      initValidationOnField(this.el)
    }
  } 

  initSelectWidget() {
    this.updateState()
    if (this.$widget.is('[readonly]')) return
    this.connect()
  
    this.$widget.unbind("click")
    this.$widget.on("click", () => { this.handleWidgetClick() })
  
    this.$search.unbind("blur")
    this.$search.on("blur", (e) => { this.possibleCloseWidget(e) })

    this.$availableItems.unbind("blur")
    this.$availableItems.on("blur", (e) => { this.possibleCloseWidget(e) })

    this.$moreInfoButtons.unbind("blur")
    this.$moreInfoButtons.on("blur", (e) => { this.possibleCloseWidget(e) })

    $(document).on("click", (e) => { this.handleDocumentClick(e) })

    $(document).keyup(function(e) {
      if (e.keyCode == 27) {
        this.collapse(this.$widget, this.$trigger, this.$target)
      }
    })

    this.$widget.delegate(".select-widget-value__delete", "click", function(e) {
      e.preventDefault()
      e.stopPropagation()

      // Uncheck checkbox
      const checkboxId = e.target.parentElement.getAttribute("data-list-item")
      const checkbox = document.getElementById(checkboxId)
      checkbox.checked = false
      $(checkbox).parent().trigger("click") // Needed for single-select
      $(checkbox).trigger("change")
    })

    this.$search.unbind("focus", this.expandWidgetHandler)
    this.$search.on("focus", (e) => { this.expandWidgetHandler(e) })

    this.$search.unbind("keydown")
    this.$search.on("keydown", (e) => { this.handleKeyDown(e) })

    this.$search.unbind("keyup")
    this.$search.on("keyup", (e) => { this.handleKeyUp(e) })

    this.$search.unbind("click")
    this.$search.on("click", (e) => {
      // Prevent bubbling the click event to the $widget (which expands/collapses the widget on click).
      e.stopPropagation()
    })
  }

  handleWidgetClick() {
    if (this.$trigger.attr("aria-expanded") === "true") {
      this.collapse(this.$widget, this.$trigger, this.$target)
    } else {
      this.expand(this.$widget, this.$trigger, this.$target)
    }
  }

  handleDocumentClick(e) {
    const clickedOutside = !this.el.is(e.target) && this.el.has(e.target).length === 0
    if (clickedOutside) {
      this.collapse(this.$widget, this.$trigger, this.$target)
    }
  }

  handleKeyUp(e) {
    const searchValue = $(e.target)
    .val()
    .toLowerCase()
    const self = this

    this.$fakeInput =
      this.$fakeInput ||
      $("<span>")
        .addClass("form-control-search")
        .css("white-space", "nowrap")
    this.$fakeInput.text(searchValue)
    this.$search.css("width", this.$fakeInput.insertAfter(this.$search).width() + 100)
    this.$fakeInput.detach()

    if (this.$selectWidget.data("value-selector") == "typeahead") {
      const url = `/${this.$selectWidget.data(
        "layout-id"
      )}/match/layout/${this.$selectWidget.data("typeahead-id")}`
      // Debounce the user input, only execute after 200ms if another one
      // hasn't started
      clearTimeout(this.timeout)
      this.$available.find(".spinner").removeAttr("hidden")
      this.timeout = setTimeout(function() {
        self.$available.find(".answer").not('.answer--blank').each(function() {
          const $answer = $(this)
          if (!$answer.find('input:checked').length) {
            $answer.remove()
          }
        })
        self.updateJson(url + '?noempty=1&q=' + searchValue, true)
      }, 200)
    } else {
      // hide the answers that do not contain the searchvalue
      let anyHits = false
      $.each(this.$answers, function() {
        const labelValue = $(this)
          .find("label")[0]
          .innerHTML.toLowerCase()
        if (labelValue.indexOf(searchValue) === -1) {
          $(this).attr("hidden", "")
        } else {
          anyHits = true
          $(this).removeAttr("hidden", "")
        }
      })

      if (anyHits) {
        this.$available.find(".has-noresults").attr("hidden", "")
      } else {
        this.$available.find(".has-noresults").removeAttr("hidden", "")
      }
    }
  }

  handleKeyDown(e) {
    const key = e.which || e.keyCode

    // If still in search text after previous search and select, ensure that
    // widget expands again to show results
    this.expand(this.$widget, this.$trigger, this.$target)

    switch (key) {
      case 38: // UP
      case 40: // DOWN
        {
          const items = this.$available.find(".answer:not([hidden]) input")
          let nextItem

          e.preventDefault()

          if (key === 38) {
            nextItem = items[items.length - 1]
          } else {
            nextItem = items[0]
          }

          if (nextItem) {
            $(nextItem).focus()
          }

          break
        }
      case 13: // ENTER
        {
          e.preventDefault()

          // Select the first (visible) item
          const firstItem = this.$available.find(".answer:not([hidden]) input").get(0)
          if (firstItem) {
            $(firstItem)
              .parent()
              .trigger("click")
          }

          break
        }
    }
  }

  expandWidgetHandler(e) {
    e.stopPropagation()
    this.expand(this.$widget, this.$trigger, this.$target)
  }

  collapse($widget, $trigger) {
    this.$selectWidget.removeClass("select-widget--open")
    $trigger.attr("aria-expanded", false)

    // Add a small delay when hiding the select widget, to allow IE to also
    // fire the default actions when selecting a radio button by clicking on
    // its label. When the input is hidden on the click event of the label
    // the input isn't actually being selected.
    setTimeout(() => {
      this.$search.val("")
      this.$target.attr("hidden", "")
      this.$answers.removeAttr("hidden")
    }, 50)
  }

  updateState() {
    const $visible = this.$current.children("[data-list-item]:not([hidden])")

    this.$current.toggleClass("empty", $visible.length === 0)
  }

  possibleCloseWidget(e) {
    const newlyFocussedElement = e.relatedTarget || document.activeElement

    if (
      !this.$selectWidget.find(newlyFocussedElement).length &&
      newlyFocussedElement &&
      !$(newlyFocussedElement).is(".modal, .page, body") &&
      this.$selectWidget.get(0).parentNode !== newlyFocussedElement
    ) {
      this.collapse(this.$widget, this.$trigger, this.$target)
    }
  }

  connectMulti() {
    return function() {
      const $item = $(this)
      const itemId = $item.data("list-item")
      const $associated = $("#" + itemId)
      const self = this

      $associated.unbind("change")
      $associated.on("change", (e) => {
        if ($(e.target).prop("checked")) {
          $item.removeAttr("hidden")
        } else {
          $item.attr("hidden", "")
        }
        self.updateState()
      })

      $associated.unbind("keydown")
      $associated.on("keydown", function(e) {
        const key = e.which || e.keyCode

        switch (key) {
          case 38: // UP
          case 40: // DOWN
            {
              const currentIndex = self.$answers.index($associated.closest(".answer"))
              let nextItem

              e.preventDefault()

              if (key === 38) {
                nextItem = self.$answers[currentIndex - 1]
              } else {
                nextItem = self.$answers[currentIndex + 1]
              }

              if (nextItem) {
                $(nextItem)
                  .find("input")
                  .focus()
              }

              break
            }
          case 13:
            {
              e.preventDefault()
              $(this).trigger("click")
              break
            }
        }
      })
    }
  }

  connectSingle() {
    const self = this;

    this.$currentItems.each((_, item) => {
      const $item = $(item)
      const itemId = $item.data("list-item")
      const $associated = $("#" + itemId)

      $associated.off("click");
      $associated.on("click", function(e) {
        e.stopPropagation();
      });

      $associated.off("change");
      $associated.on("change", function() {
        // First hide all items in the drop-down display
        self.$currentItems.each((_, currentItem) => {
          $(currentItem).attr("hidden", "")
        })
        // Then show the one selected
        if ($associated.prop("checked")) {
          $item.removeAttr("hidden")
        }
        // Update state so as to show "select option" default text for nothing
        // selected
        self.updateState()
      });

      $associated.parent().unbind("keypress")
      $associated.parent().on("keypress", (e) => {
        // KeyCode Enter or Spacebar
        if (e.keyCode === 13 || e.keyCode === 32) {
          e.preventDefault()
          $(e.target).parent().trigger("click")
        }
      })

      $associated.parent().off("click")
      $associated.parent().on("click", () => {
        // Need to collapse on click (not change) otherwise drop-down will
        // collapse when changing using the keyboard
        this.collapse(this.$widget, this.$trigger, this.$target)
      })
    })
  }

  connect() {
    if (this.multi) {
      this.$currentItems.each(this.connectMulti())
    } else {
      this.connectSingle()
    }
  }

  currentLi(multi, field, value_id, value_text, value_html, checked) {
    if (multi && !value_id) {
      return $('<li class="none-selected">blank</li>')
    }

    const valueId = value_id ? field + "_" + value_id : field + "__blank"
    const className = value_id ? "" : "current__blank"
    const deleteButton = '<button type="button" class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times</button>'
    const $li = $(
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
    )
    $li.data('list-text', value_text)
    $li.data('list-id', value_id)
    $li.find('span').html(value_html)
    return $li
  }

  availableLi(multi, field, value_id, value_text, label, checked) {
    if (this.multi && !value_id) {
      return null
    }

    const valueId = value_id ? field + "_" + value_id : field + "__blank"
    const classNames = value_id ? "answer" : "answer answer--blank"

    // Add space at beginning to keep format consistent with that in template
    const detailsButton =
      ' <div class="details">' +
      '<button type="button" class="btn btn-small btn-default btn-js-more-info" data-record-id="' + value_id +
      '" aria-describedby="lbl-' + valueId +
      '" data-target="' + this.el.data('details-modal') + // TODO: get id of modal
      '" data-toggle="modal">' +
      "Details" +
      "</button>" +
      "</div>"

    const $li = $(
      '<li class="' +
        classNames +
        '">' +
        '<div class="control">' +
        '<div class="' +
        (multi ? "checkbox" : "radio-group__option") +
        '">' +
        '<input id="' +
        valueId +
        '" type="' +
        (multi ? "checkbox" : "radio") +
        '" name="' +
        field +
        '" ' +
        (checked ? " checked" : "") +
        (this.required && !this.multi ? ' required aria-required="true"' : "") +
        ' value="' +
        (value_id || "") +
        '" class="' +
        (multi ? "" : "visually-hidden") +
        '" aria-labelledby="lbl-' +
        valueId +
        '"> ' + // Add space to keep spacing consistent with templates
        '<label id="lbl-' +
        valueId +
        '" for="' +
        valueId +
        '">' + label +
        "</label>" +
        "</div>" +
        "</div>" +
        (value_id ? detailsButton : "") +
        "</li>"
    )
    $li.data('list-text', value_text)
    $li.data('list-id', value_id)
    return $li
  }

  //Some odd scoping issues here - but it works
  updateJson(url, typeahead) {
    this.loadCounter++
    const self = this;
    const myLoad = this.loadCounter // ID of this process
    this.$available.find(".spinner").removeAttr("hidden")
    const currentValues = this.$available
      .find("input:checked")
      .map(function() {
        return parseInt($(this).val());
      })
      .get()

    // Remove existing items if needed, now that we have found out which ones are selected
    if (!typeahead) {
      this.$available.find(".answer").remove()
    }

    const field = this.$selectWidget.data("field")
    // If we cancel this particular loop, then we don't want to remove the
    // spinner if another one has since started running
    let hideSpinner = true
    $.getJSON(url, function(data) {
      if (data.error === 0) {
        if (myLoad != this.loadCounter) { // A new one has started running
          hideSpinner = false // Don't remove the spinner on completion
          return
        }

        if (typeahead) {
          // Need to keep currently selected item
          this.$currentItems.filter(':hidden').remove()
        } else {
          this.$currentItems.remove()
        }
        
        const checked = currentValues.includes(NaN)
        if (this.multi) {
          this.$search
            .parent()
            .prevAll(".none-selected")
            .remove() // Prevent duplicate blank entries
            this.$search
            .parent()
            .before(this.currentLi(this.multi, field, null, "", "blank", checked))
            this.$available.append(this.availableLi(this.multi, field, null, "", "blank", checked))
        }

        $.each(data.records, (recordIndex, record) => {
          const checked = currentValues.includes(record.id)
          if (!typeahead || (typeahead && !checked)) {
            this.$search
              .parent()
              .before(
                this.currentLi(this.multi, field, record.id, record.label, record.html, checked)
              ).before(' ') // Ensure space between elements
              this.$available.append(
                this.availableLi(this.multi, field, record.id, record.label, record.html, checked)
            )
          }
        })

        this.$currentItems = this.$current.find("[data-list-item]")
        this.$available = this.$selectWidget.find(".available")
        this.$availableItems = this.$selectWidget.find(".available .answer input")
        this.$moreInfoButtons = this.$selectWidget.find(
          ".available .answer .btn-js-more-info"
        )
        this.$answers = this.$selectWidget.find(".answer")

        this.updateState()
        this.connect()

        this.$availableItems.on("blur", (e) => { this.possibleCloseWidget(e) })
        this.$moreInfoButtons.on("blur", (e) => { this.possibleCloseWidget(e) })
        this.$moreInfoButtons.each((_, button) => {
          import(/* webpackChunkName: "more-info-button" */ '../../../button/lib/more-info-button')
            .then(({ default: MoreInfoButton }) => { new MoreInfoButton(button); }
            );
        })

      } else {
        const errorMessage =
          data.error === 1 ? data.message : "Oops! Something went wrong."
        const errorLi = $(
          '<li class="answer answer--blank alert alert-danger d-flex flex-row justify-content-start"><span class="control"><label>' +
            errorMessage +
            "</label></span></li>"
        )
        this.$available.append(errorLi)
      }
    })
      .fail(function(jqXHR, textStatus, textError) {
        const errorMessage = "Oops! Something went wrong."
        logging.error(
          "Failed to make request to " +
            url +
            ": " +
            textStatus +
            ": " +
            textError
        )
        const errorLi = $(
          '<li class="answer answer--blank alert alert-danger"><span class="control"><label>' +
            errorMessage +
            "</label></span></li>"
        )
        self.$available.append(errorLi)
      })
      .always(function() {
        if (hideSpinner) {
          self.$available.find(".spinner").attr("hidden", "")
        }
      })
  }

  fetchOptions() {
    const filterEndpoint = this.$selectWidget.data("filter-endpoint")
    const filterFields = this.$selectWidget.data("filter-fields")
    const submissionToken = this.$selectWidget.data("submission-token")

    if (!Array.isArray(filterFields)) {
      throw 'Invalid data-filter-fields found. It should be a proper JSON array of fields.'
    }

    // Collect values of linked fields
    const values = ["submission-token=" + submissionToken]
    $.each(filterFields, function(_, field) {

      $("input[name=" + field + "]").each(function(_, input) {
        const $input = $(input)

        switch ($input.attr("type")) {
          case "number":
            values.push(field + "=" + $input.val())
            break
          case "text":
            values.push(field + "=" + $input.val())
            break
          case "radio":
            if (input.checked) {
              values.push(field + "=" + $input.val())
            }
            break
          case "checkbox":
            if (input.checked) {
              values.push(field + "=" + $input.val())
            }
            break
          case "hidden": // Tree values stored as hidden field
            values.push(field + "=" + $input.val())
            break
        }
      })
    })

    // Bail out if the options haven't changed
    const fetchParams = values.join("&")

    if (this.lastFetchParams === fetchParams) {
      return
    }
    this.lastFetchParams = null

    this.updateJson(filterEndpoint + "?" + fetchParams)
    this.lastFetchParams = fetchParams
  }

  expand($widget, $trigger, $target) {
    if ($trigger.attr("aria-expanded") === "true") {
      return
    }
    this.$selectWidget.addClass("select-widget--open")
    this.$available.find(".spinner").attr("hidden", "")
    $trigger.attr("aria-expanded", true)

    if (
      this.$selectWidget.data("filter-endpoint") &&
      this.$selectWidget.data("filter-endpoint").length
    ) {
      try {
        this.fetchOptions()
      } catch (e) {
        logging.error(e)
      }
    }

    const widgetTop = $widget.offset().top
    const widgetBottom = widgetTop + $widget.outerHeight()
    const viewportTop = $(window).scrollTop()
    const viewportBottom = viewportTop + $(window).height() - 60
    const minimumRequiredSpace = 200
    const fitsBelow = widgetBottom + minimumRequiredSpace < viewportBottom
    const fitsAbove = widgetTop - minimumRequiredSpace > viewportTop
    const expandAtTop = fitsAbove && !fitsBelow
    $target.toggleClass("available--top", expandAtTop)
    $target.removeAttr("hidden")

    if (this.$search.get(0) !== document.activeElement) {
      this.$search.focus()
    }
  }
}

export default SelectWidgetComponent
