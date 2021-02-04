const setupTreeFields = (() => {
  var setupTreeField = function() {
    var $this = $(this);
    var id = $this.data("column-id");
    var multiValue = $this.data("is-multivalue");
    var $treeContainer = $this.find(".tree-widget-container");
    var field = $treeContainer.data("field");
    var layout_identifier = $("body").data("layout-identifier");
    var endNodeOnly = $treeContainer.data("end-node-only");
    var idsAsParams = $treeContainer.data("ids-as-params");

    var treeConfig = {
      core: {
        check_callback: true,
        force_text: true,
        themes: { stripes: true },
        worker: false,
        data: {
          url: function() {
            return (
              "/" +
              layout_identifier +
              "/tree" +
              new Date().getTime() +
              "/" +
              id +
              "?" +
              idsAsParams
            );
          },
          data: function(node) {
            return { id: node.id };
          }
        }
      },
      plugins: []
    };

    if (!multiValue) {
      treeConfig.core.multiple = false;
    } else {
      treeConfig.plugins.push("checkbox");
    }

    $treeContainer.on("changed.jstree", function(e, data) {
      // remove all existing hidden value fields
      $treeContainer.nextAll(".selected-tree-value").remove();
      var selectedElms = $treeContainer.jstree("get_selected", true);

      $.each(selectedElms, function() {
        // store the selected values in hidden fields as children of the element
        var node = $(
          '<input type="hidden" class="selected-tree-value" name="' +
            field +
            '" value="' +
            this.id +
            '" />'
        ).insertAfter($treeContainer);
        var text_value = data.instance.get_path(this, "#");
        node.data("text-value", text_value);
      });
      // Hacky: we need to submit at least an empty value if nothing is
      // selected, to ensure the forward/back functionality works. XXX If the
      // forward/back functionality is removed, this can be removed too.
      if (selectedElms.length == 0) {
        $treeContainer.after(
          '<input type="hidden" class="selected-tree-value" name="' +
            field +
            '" value="" />'
        );
      }

      $treeContainer.trigger("change");
    });

    $treeContainer.on("select_node.jstree", function(e, data) {
      if (data.node.children.length == 0) {
        return;
      }
      if (endNodeOnly) {
        $treeContainer.jstree(true).deselect_node(data.node);
        $treeContainer.jstree(true).toggle_node(data.node);
      } else if (multiValue) {
        $treeContainer.jstree(true).open_node(data.node);
      }
    });

    $treeContainer.jstree(treeConfig);

    // hack - see https://github.com/vakata/jstree/issues/1955
    $treeContainer.jstree(true).settings.checkbox.cascade = "undetermined";
  };

  var setupTreeFields = function(context) {
    var $fields = $('[data-column-type="tree"]', context);
    $fields
      .filter(function() {
        return $(this).find(".tree-widget-container").length;
      })
      .each(setupTreeField);
  };

  return context => {
    setupTreeFields(context);
  };
})();

export { setupTreeFields };
