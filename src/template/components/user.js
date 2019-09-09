const setupDataTable = (id, context) => {
  const tableEl = $(id, context);
  if (!tableEl.length) return;
  tableEl.dataTable({
    order: [[1, "asc"]]
  });
};

const setup = context => {
  setupDataTable("#user-table-active", context);
  setupDataTable("#user-table-request", context);
};

export default setup;
