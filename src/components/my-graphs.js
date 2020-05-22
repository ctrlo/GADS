const setupMyGraphs = (() => {
  const setupDataTable = context => {
    const dtableEl = $("#mygraphs-table", context);
    if (!dtableEl.length) return;
    dtableEl.dataTable({
      columnDefs: [
        {
          targets: 0,
          orderable: false
        }
      ],
      pageLength: 50,
      order: [[1, "asc"]]
    });
  };

  return context => {
    setupDataTable(context);
  };
})();

export { setupMyGraphs };
