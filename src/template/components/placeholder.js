const setupPlaceholder = context => {
  $("input, text", context).placeholder();
};

const setup = context => {
  setupPlaceholder(context);
};

export default setup;
