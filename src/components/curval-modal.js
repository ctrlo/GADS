import { setupSelectWidgets } from "./select-widgets";
import { getFieldValues } from "../lib/get-field-values";
import { guid as Guid } from "../lib/guid";

const setupCurvalModal = (() => {
  const curvalModalValidationSucceeded = (form, values, context) => {
    var form_data = form.serialize();
    var modal_field_ids = form.data("modal-field-ids");
    var col_id = form.data("curval-id");
    var instance_name = form.data("instance-name");
    //var parent_current_id = form.data("parent-current-id");
    var guid = form.data("guid");
    var hidden_input = $("<input>", context).attr({
      type: "hidden",
      name: "field" + col_id,
      value: form_data
    });
    var $formGroup = $("div[data-column-id=" + col_id + "]", context);
    var valueSelector = $formGroup.data("value-selector");

    if (valueSelector === "noshow") {
      var row_cells = $('<tr class="curval_item">', context);
      jQuery.map(modal_field_ids, function(element) {
        var control = form.find('[data-column-id="' + element + '"]');
        var value = getFieldValues(control);
        value = values["field" + element];
        value = $("<div />", context)
          .text(value)
          .html();
        row_cells.append(
          $('<td class="curval-inner-text">', context).append(value)
        );
      });
      var links = $(
        `<td>
        <a class="curval-modal" style="cursor:pointer" data-layout-id="${col_id}" data-instance-name="${instance_name}">edit</a> | <a class="curval_remove" style="cursor:pointer">remove</a>
      </td>`,
        context
      );
      row_cells.append(links.append(hidden_input));
      if (guid) {
        var hidden = $('input[data-guid="' + guid + '"]', context).val(
          form_data
        );
        hidden.closest(".curval_item").replaceWith(row_cells);
      } else {
        $(`#curval_list_${col_id}`, context)
          .find("tbody")
          .prepend(row_cells);
      }
    } else {
      var $widget = $formGroup.find(".select-widget").first();
      var multi = $widget.hasClass("multi");
      var $currentItems = $formGroup.find(".current [data-list-item]");

      var $search = $formGroup.find(".current .search");
      var $answersList = $formGroup.find(".available");

      if (!multi) {
        /* Deselect current selected value */
        $currentItems.attr("hidden", "");
        $answersList.find("li input").prop("checked", false);
      }

      var textValue = jQuery
        .map(modal_field_ids, function(element) {
          var value = values["field" + element];
          return $("<div />")
            .text(value)
            .html();
        })
        .join(", ");

      guid = Guid();
      const id = `field${col_id}_${guid}`;
      var deleteButton = multi
        ? '<button class="close select-widget-value__delete" aria-hidden="true" aria-label="delete" title="delete" tabindex="-1">&times;</button>'
        : "";
      $search.before(
        `<li data-list-item="${id}">${textValue}${deleteButton}</li>`
      ).before(' '); // Ensure space between elements in widget
      var inputType = multi ? "checkbox" : "radio";
      $answersList.append(`<li class="answer">
        <span class="control">
            <label id="${id}_label" for="${id}">
                <input id="${id}" name="field${col_id}" type="${inputType}" value="${form_data}" class="${
        multi ? "" : "visually-hidden"
      }" checked aria-labelledby="${id}_label">
                <span>${textValue}</span>
            </label>
        </span>
        <span class="details">
            <a class="curval_remove" style="cursor:pointer">remove</a>
        </span>
      </li>`);

      /* Reinitialize widget */
      setupSelectWidgets($formGroup);
    }

    $(".modal.in", context).modal("hide");
  };

  const curvalModalValidationFailed = (form, errorMessage) => {
    form
      .find(".alert")
      .text(errorMessage)
      .removeAttr("hidden");
    form
      .parents(".modal-content")
      .get(0)
      .scrollIntoView();
    form.find("button[type=submit]").prop("disabled", false);
  };

  const setupAddButton = context => {
    $(document, context).on("mousedown", ".curval-modal", function(e) {
      var layout_id = $(e.target).data("layout-id");
      var instance_name = $(e.target).data("instance-name");
      //var parent_current_id = $(e.target).data("parent-current-id");
      var current_id = $(e.target).data("current-id");
      var hidden = $(e.target)
        .closest(".curval_item")
        .find(`input[name=field${layout_id}]`);
      var form_data = hidden.val();
      var mode = hidden.length ? "edit" : "add";
      var guid;

      if (mode === "edit") {
        guid = hidden.data("guid");
        if (!guid) {
          guid = Guid();
          hidden.attr("data-guid", guid);
        }
      }

      var m = $("#curval_modal", context);
      m.find(".modal-body").text("Loading...");
      var url = current_id
        ? `/record/${current_id}`
        : `/${instance_name}/record/`;
      m.find(".modal-body").load(
        `${url}?include_draft&modal=${layout_id}&${form_data}`,
        function() {
          if (mode === "edit") {
            m.find("form").data("guid", guid);
          }
          Linkspace.init(m);
        }
      );
      m.on("focus", ".datepicker", function() {
        $(this).datepicker({
          format: m.attr("data-dateformat-datepicker"),
          autoclose: true
        });
      });
      m.modal();
    });
  };

  const setupSubmit = context => {
    $("#curval_modal", context).on("submit", ".curval-edit-form", function(e) {
      e.preventDefault();
      var form = $(this);
      var form_data = form.serialize();

      form.addClass("edit-form--validating");
      form.find(".alert").attr("hidden", "");

      $.post(
        form.attr("action") + "?validate&include_draft&source=" + form.data("curval-id"),
        form_data,
        function(data) {
          if (data.error === 0) {
            curvalModalValidationSucceeded(form, data.values);
          } else {
            var errorMessage =
              data.error === 1 ? data.message : "Oops! Something went wrong.";
            curvalModalValidationFailed(form, errorMessage);
          }
        },
        "json"
      )
        .fail(function(jqXHR, textstatus, errorthrown) {
          var errorMessage = `Oops! Something went wrong: ${textstatus}: ${errorthrown}`;
          curvalModalValidationFailed(form, errorMessage);
        })
        .always(function() {
          form.removeClass("edit-form--validating");
        });
    });
  };

  const setupRemoveCurval = context => {
    $(".curval_group", context).on("click", ".curval_remove", function() {
      if (confirm("Are you sure want to permanently remove this item?"))
      {
        $(this)
          .closest(".curval_item")
          .remove();
      } else {
        e.preventDefault();
      }
    });

    $(".select-widget", context).on("click", ".curval_remove", function() {
      var fieldId = $(this)
        .closest(".answer")
        .find("input")
        .prop("id");
      $(this)
        .closest(".select-widget")
        .find(`.current li[data-list-item=${fieldId}]`)
        .remove();
      $(this)
        .closest(".answer")
        .remove();
    });
  };

  return context => {
    setupAddButton(context);
    setupSubmit(context);
    setupRemoveCurval(context);
  };
})();

export { setupCurvalModal };
