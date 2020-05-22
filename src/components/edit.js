import { setupCurvalModal } from "./curval-modal";
import { setupDatePicker } from "./date-picker";

const setupEdit = (() => {
  const setupCloneAndRemove = context => {
    $(document, context).on("click", ".cloneme", function() {
      var parent = $(this).parents(".input_holder");
      var cloned = parent.clone();
      cloned.removeAttr("id").insertAfter(parent);
      cloned.find(":text").val("");
      cloned.find(".datepicker").datepicker({
        format: parent.attr("data-dateformat-datepicker"),
        autoclose: true
      });
    });
    $(document, context).on("click", ".removeme", function() {
      var parent = $(this).parents(".input_holder");
      if (parent.siblings(".input_holder").length > 0) {
        parent.remove();
      }
    });
  };

  const setupHelpTextModal = context => {
    $("#helptext_modal", context).on("show.bs.modal", function(e) {
      var loadurl = $(e.relatedTarget).data("load-url");
      $(this)
        .find(".modal-body")
        .load(loadurl);
    });

    $(document, context).on("click", ".more-info", function(e) {
      var record_id = $(e.target).data("record-id");
      var m = $("#readmore_modal", context);
      m.find(".modal-body").text("Loading...");
      m.find(".modal-body").load("/record_body/" + record_id);

      /* Trigger focus restoration on modal close */
      m.one("show.bs.modal", function(showEvent) {
        /* Only register focus restorer if modal will actually get shown */
        if (showEvent.isDefaultPrevented()) {
          return;
        }
        m.one("hidden.bs.modal", function() {
          $(e.target, context).is(":visible") &&
            $(e.target, context).trigger("focus");
        });
      });

      /* Stop propagation of the escape key, as may have side effects, like closing select widgets. */
      m.one("keyup", function(e) {
        if (e.keyCode == 27) {
          e.stopPropagation();
        }
      });

      m.modal();
    });
  };

  const setupTypeahead = context => {
    $('input[type="text"][id^="typeahead_"]', context).each(
      (i, typeaheadEl) => {
        $(typeaheadEl, context).change(function() {
          if (!$(this).val()) {
            $(`#${typeaheadEl.id}_value`, context).val("");
          }
        });
        $(typeaheadEl, context).typeahead({
          delay: 500,
          matcher: function() {
            return true;
          },
          sorter: function(items) {
            return items;
          },
          afterSelect: function(selected) {
            $(`#${typeaheadEl.id}_value`, context).val(selected.id);
          },
          source: function(query, process) {
            return $.ajax({
              type: "GET",
              url: `/${$(typeaheadEl, context).data(
                "layout-id"
              )}/match/layout/${$(typeaheadEl).data("typeahead-id")}`,
              data: { q: query },
              success: function(result) {
                process(result);
              },
              dataType: "json"
            });
          }
        });
      }
    );
  };

  return context => {
    setupCloneAndRemove(context);
    setupHelpTextModal(context);
    setupCurvalModal(context);
    setupDatePicker(context);
    setupTypeahead(context);
  };
})();

export { setupEdit };
