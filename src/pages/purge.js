const PurgePage = () => {
  $("#selectall").click(function() {
    $(".record_selected").prop("checked", this.checked);
  });
};

export { PurgePage };
