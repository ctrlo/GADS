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

const setup = context => {
  setupDataTable(context);
};

export default setup;
