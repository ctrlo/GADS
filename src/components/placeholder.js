const setupPlaceholder = (() => {
  const setupPlaceholder = context => {
    $("input, text", context).placeholder();
  };

  return context => {
    setupPlaceholder(context);
  };
})()

export { setupPlaceholder };
