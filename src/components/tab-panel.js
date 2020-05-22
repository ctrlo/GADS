const SetupTabPanel = function() {
  var $this = $(this);
  var $tabs = $this.find('[role="tab"]');
  var $panels = $this.find('[role="tabpanel"]');

  var indexedTabs = [];

  $tabs.each(function(i) {
    indexedTabs[i] = $(this);
    $(this).data("index", i);
  });

  var selectTab = function(e) {
    if (e) {
      e.preventDefault();
    }

    var $thisTab = $(this);

    if ($thisTab.attr("aria-selected") === "true") {
      return false;
    }

    var $thisPanel = $panels.filter($thisTab.attr("href"));

    var $activeTab = $tabs.filter('[aria-selected="true"]');
    var $activePanel = $panels.filter(".active");

    $activeTab.attr("aria-selected", false);
    $activePanel.removeClass("active");

    $thisTab.attr("aria-selected", true);
    $thisPanel.addClass("active");

    $thisTab.attr("tabindex", "0");
    $tabs.filter('[aria-selected="false"]').attr("tabindex", "-1");

    return false;
  };

  var moveTab = function(e) {
    var $thisTab = $(this);
    var index = $thisTab.data("index");
    var k = e.keyCode;
    var left = Linkspace.constants.ARROW_LEFT,
      right = Linkspace.constants.ARROW_RIGHT;
    if ([left, right].indexOf(k) < 0) {
      return;
    }
    var $nextTab;
    if (
      (k === left && ($nextTab = indexedTabs[index - 1])) ||
      (k === right && ($nextTab = indexedTabs[index + 1]))
    ) {
      selectTab.call($nextTab);
      $nextTab.focus();
    }
  };

  $tabs.on("click", selectTab);
  $tabs.on("keyup", moveTab);
  $tabs.filter('[aria-selected="false"]').attr("tabindex", "-1");
};

export { SetupTabPanel };
