import { Component } from "../component";

class SaveViewButtonComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initSaveView();
  }

  initSaveView() {
    this.el.on("click", (ev) => {
      this.saveView(ev);
    });
  }

  saveView(ev) {
    $(".filter").each((i, el) => {
      if (!$(el).queryBuilder("validate")) ev.preventDefault();
      const res = $(el).queryBuilder("getRules");
      $(el)
        .next("#filter")
        .val(JSON.stringify(res, null, 2));
    });
  }
}

export default SaveViewButtonComponent;
