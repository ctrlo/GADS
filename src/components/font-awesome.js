const setupFontAwesome = () => {
  if (!window.FontDetect) return;
  if (!FontDetect.isFontLoaded("14px/1 FontAwesome")) {
    $(".use-icon-font").hide();
    $(".use-icon-png").show();
  }
};

export { setupFontAwesome };
