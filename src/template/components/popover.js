const setupPopover = context => {
  $('[data-toggle="popover"]', context).popover({
    placement: "auto",
    html: true
  });
};

const setup = context => {
  setupPopover(context);
};

export default setup;
