import { SetupTabPanel } from "../components/tab-panel";
import { onDisclosureClick } from "../components/disclosure-widgets";

const LayoutPage = context => {
  $(".tab-interface").each(SetupTabPanel);

  var $config = $("#permission-configuration");
  var $rule = $(".permission-rule", context);

  var $ruleTemplate = $("#permission-rule-template");
  var $cancelRuleButton = $rule.find("button.cancel-permission");
  var $addRuleButton = $rule.find("button.add-permission");

  var closePermissionConfig = function() {
    $config.find("input").each(function() {
      $(this).prop("checked", false);
    });
    $config.attr("hidden", "");
    $("#configure-permissions")
      .removeAttr("hidden")
      .focus();
  };

  var handlePermissionChange = function() {
    var $permission = $(this);
    var groupId = $permission.data("group-id");

    var $editButton = $permission.find("button.edit");
    var $deleteButton = $permission.find("button.delete");
    var $okButton = $permission.find("button.ok");

    $permission.find("input").on("change", function() {
      var pClass = "permission-" + $(this).data("permission-class");
      var checked = $(this).prop("checked");
      $permission.toggleClass(pClass, checked);

      if (checked) {
        return;
      }

      $(this)
        .siblings("div")
        .find("input")
        .each(function() {
          $(this).prop(checked);
          pClass = "permission-" + $(this).data("permission-class");
          $permission.toggleClass(pClass, checked);
        });
    });

    $editButton.on("expand", function() {
      $permission.addClass("edit");
      $permission.find(".group-name").focus();
    });

    $deleteButton.on("click", function() {
      $("#permissions").removeClass("permission-group-" + groupId);
      $permission.remove();
    });

    $okButton.on("click", function() {
      $permission.removeClass("edit");
      $okButton.parent().removeClass("expanded");
      $editButton.attr("aria-expanded", false).focus();
    });
  };

  $cancelRuleButton.on("click", closePermissionConfig);

  $addRuleButton.on("click", function() {
    var $newRule = $($ruleTemplate.html());
    var $currentPermissions = $("#current-permissions ul");
    var $selectedGroup = $config.find("option:selected");

    var groupId = $selectedGroup.val();

    $config.find("input").each(function() {
      var $input = $(this);
      var state = $input.prop("checked");

      if (state) {
        $newRule.addClass(
          "permission-" + $input.data("permission-class").replace(/_/g, "-")
        );
      }

      $newRule
        .find("input#" + $input.attr("id"))
        .prop("checked", state)
        .attr("id", $input.attr("id") + groupId)
        .attr("name", $input.attr("name") + groupId)
        .next("label")
        .attr("for", $input.attr("id"));
    });

    $newRule.appendTo($currentPermissions);
    $newRule.attr("data-group-id", groupId);

    $("#permissions").addClass("permission-group-" + groupId);
    $newRule.find(".group-name").text($selectedGroup.text());

    $newRule.find("button.edit").on("click", onDisclosureClick);

    handlePermissionChange.call($newRule);
    closePermissionConfig();
  });

  $("#configure-permissions").on("click", function() {
    var $permissions = $("#permissions");
    var selected = false;
    $("#permission-configuration")
      .find("option")
      .each(function() {
        var $option = $(this);
        $option.removeAttr("disabled");
        if ($permissions.hasClass("permission-group-" + $option.val())) {
          $option.attr("disabled", "");
        } else {
          // make sure the first non-disabled option gets selected
          if (!selected) {
            $option.attr("selected", "");
            selected = true;
          }
        }
      });
    $(this).attr("hidden", "");
    $("#permission-configuration").removeAttr("hidden");

    $(this)
      .parent()
      .find("h4")
      .focus();
  });

  $("#current-permissions .permission").each(handlePermissionChange);
};

export { LayoutPage };
