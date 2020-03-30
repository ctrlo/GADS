const setupOpenModalOnLoad = (id, context) => {
  const modalEl = $(id, context);
  if (modalEl.data("open-on-load")) {
    modalEl.modal("show");
  }
};

const setup = context => {
  setupOpenModalOnLoad("#modalregister", context);
  setupOpenModalOnLoad("#modal-reset-password", context);
};

export default setup;
