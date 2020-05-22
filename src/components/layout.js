const setupLayout = (() => {
  const setupDemoButtons = context => {
    const demo_delete = () => {
      var ref = $("#jstree_demo_div", context).jstree(true),
        sel = ref.get_selected();
      if (!sel.length) {
        return false;
      }
      ref.delete_node(sel);
    };

    $("#btnDeleteNode", context).click(demo_delete);

    const demo_create = () => {
      var ref = $("#jstree_demo_div", context).jstree(true),
        sel = ref.get_selected();
      if (sel.length) {
        sel = sel[0];
      } else {
        sel = "#";
      }
      sel = ref.create_node(sel, { type: "file" });
      if (sel) {
        ref.edit(sel);
      }
    };

    $("#btnAddNode", context).click(demo_create);

    const demo_rename = () => {
      var ref = $("#jstree_demo_div", context).jstree(true),
        sel = ref.get_selected();
      if (!sel.length) {
        return false;
      }
      sel = sel[0];
      ref.edit(sel);
    };

    $("#btnRenameNode", context).click(demo_rename);
  };

  // No longer used? Where is #selectall ?
  const setupSelectAll = context => {
    $("#selectall", context).click(() => {
      if ($(".check_perm:checked", context).length == 7) {
        $(".check_perm", context).prop("checked", false);
      } else {
        $(".check_perm", context).prop("checked", true);
      }
    });
  };

  const setupSortableHandle = context => {
    if (!$(".sortable", context).length) return;
    $(".sortable", context).sortable({
      handle: ".drag"
    });
  };

  const setupTreeDemo = context => {
    const treeEl = $("#jstree_demo_div", context);
    if (!treeEl.length) return;
    treeEl.jstree({
      core: {
        check_callback: true,
        force_text: true,
        themes: { stripes: true },
        data: {
          url: () =>
            `/${treeEl.data(
              "layout-identifier"
            )}/tree${new Date().getTime()}/${treeEl.data("column-id")}?`,
          data: node => ({ id: node.id })
        }
      }
    });
  };

  const setupDropdownValues = context => {
    $("div#legs", context).on("click", ".add", event => {
      $(event.currentTarget, context)
        .closest("#legs")
        .find(".sortable").append(`
          <div class="request-row">
            <p>
              <input type="hidden" name="enumval_id">
              <input type="text" class="form-control" style="width:80%; display:inline" name="enumval">
              <button type="button" class="close closeme" style="float:none">&times;</button>
              <span class="fa fa-hand-paper-o fa-lg use-icon-font close drag" style="float:none"></span>
            </p>
          </div>
      `);
      $(".sortable", context).sortable("refresh");
    });
    $("div#legs").on("click", ".closeme", event => {
      var count = $(".request-row", context).length;
      if (count < 2) return;
      $(event.currentTarget, context)
        .parents(".request-row")
        .remove();
    });
  };

  const setupTableDropdown = context => {
    $("#refers_to_instance_id", context).change(event => {
      var divid = `#instance_fields_${$(event.currentTarget, context).val()}`;
      $(".instance_fields", context).hide();
      $(divid, context).show();
    });
  };

  const setupAutoValueField = context => {
    $("#related_field_id", context).change(event => {
      var divid = $(event.currentTarget)
        .find(":selected")
        .data("instance_id");
      $(".autocur_instance", context).hide();
      $(`#autocur_instance_${divid}`, context).show();
    });

    $("#filval_related_field_id", context).change(function() {
      var divid = $(this).val();
      $(".filval_curval", context).hide();
      $("#filval_curval_" + divid, context).show();
    });
  };

  const setupJsonFilters = context => {
    $('div[id^="builder"]', context).each((i, builderEl) => {
      const filterBase = $(builderEl).data("filter-base");
      if (!filterBase) return;
      var data = base64.decode(filterBase);
      $(builderEl).queryBuilder("setRules", JSON.parse(data));
    });
  };

  const setupDisplayConditionsBuilder = context => {
    const conditionsBuilder = $("#displayConditionsBuilder", context);
    if (!conditionsBuilder.length) return;
    const builderData = conditionsBuilder.data();
    conditionsBuilder.queryBuilder({
      filters: builderData.filters,
      allow_groups: 0,
      operators: [
        { type: "equal", accept_values: true, apply_to: ["string"] },
        { type: "contains", accept_values: true, apply_to: ["string"] },
        { type: "not_equal", accept_values: true, apply_to: ["string"] },
        { type: "not_contains", accept_values: true, apply_to: ["string"] }
      ]
    });
    if (builderData.filterBase) {
      const data = base64.decode(builderData.filterBase);
      conditionsBuilder.queryBuilder("setRules", JSON.parse(data));
    }
  };

  const setupSubmitSave = context => {
    $("#submit_save", context).click(function() {
      const res = $("#displayConditionsBuilder", context).queryBuilder(
        "getRules"
      );
      $("#displayConditions", context).val(JSON.stringify(res, null, 2));

      const current_builder = `#builder${$(
        "#refers_to_instance_id",
        context
      ).val()}`;
      const jstreeDemoDivEl = $("#jstree_demo_div", context);
      if (jstreeDemoDivEl.length && jstreeDemoDivEl.is(":visible")) {
        const v = jstreeDemoDivEl.jstree(true).get_json("#", { flat: false });
        const mytext = JSON.stringify(v);
        const data = jstreeDemoDivEl.data();
        $.ajax({
          async: false,
          type: "POST",
          url: `/${data.layoutIdentifier}/tree/${data.columnId}`,
          data: { data: mytext, csrf_token: data.csrfToken }
        }).done(() => {
          // eslint-disable-next-line no-alert
          alert("Tree has been updated");
        });
        return true;
      } else if ($(current_builder, context).is(":visible")) {
        UpdateFilter($(current_builder, context));
      }
      return true;
    });
  };

  const setupType = context => {
    $("#type", context)
      .on("change", function() {
        var $mf = $("#manage-fields", context);
        var current_type = $mf.data("column-type");
        var new_type = $(this).val();
        $mf.removeClass("column-type-" + current_type);
        $mf.addClass("column-type-" + new_type);
        $mf.data("column-type", new_type);
        if (new_type == "rag" || new_type == "intgr" || new_type == "person") {
          $("#checkbox-multivalue", context).hide();
        } else {
          $("#checkbox-multivalue", context).show();
        }
      })
      .trigger("change");
  };

  const setupNotify = context => {
    $("#notify_on_selection", context)
      .on("change", function() {
        if ($(this).prop("checked")) {
          $("#notify-options", context).show();
        } else {
          $("#notify-options", context).hide();
        }
      })
      .trigger("change");
  };

  return context => {
    setupDemoButtons(context);
    setupSelectAll(context);
    setupSortableHandle(context);
    setupTreeDemo(context);
    setupDropdownValues(context);
    setupTableDropdown(context);
    setupAutoValueField(context);
    setupJsonFilters(context);
    setupDisplayConditionsBuilder(context);
    setupSubmitSave(context);
    setupType(context);
    setupNotify(context);
  };
})();

export { setupLayout };
