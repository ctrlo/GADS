const setupLogin = (() => {
  const setupOpenModalOnLoad = (id, context) => {
    const modalEl = $(id, context);
    if (modalEl.data("open-on-load")) {
      modalEl.modal("show");
    }
  };

  return context => {
    setupOpenModalOnLoad("#modalregister", context);
    setupOpenModalOnLoad("#modal-reset-password", context);
  };
})();

export { setupLogin };
