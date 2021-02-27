const setupJStreeButtons = (() => {
  var setupJStreeButtons = function($treeContainer) {

    // Set up expand/collapse buttons located above widget
    $treeContainer.prevAll('.jstree-expand-all').on('click', function() {
        $treeContainer.jstree(true).open_all();
    });
    $treeContainer.prevAll('.jstree-collapse-all').on('click', function() {
        $treeContainer.jstree(true).close_all();
    });
    $treeContainer.prevAll('.jstree-reload').on('click', function() {
        $treeContainer.jstree(true).refresh();
    });
  };

  return ($treeContainer) => {
    setupJStreeButtons($treeContainer);
  };
})();

export { setupJStreeButtons };
