const setupPopover = (() => {
  const setupPopover = context => {
    $('[data-toggle="popover"]', context).popover({
      placement: "auto",
      html: true
    });
  };

  return context => {
    setupPopover(context);
  };
})();

export { setupPopover };
