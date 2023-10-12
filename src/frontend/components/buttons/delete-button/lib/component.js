import { Component } from "component";
import { logging } from "logging";

class DeleteButtonComponent extends Component {
  constructor(element) {
    super(element);
    this.el = $(this.element);
    this.initDelete();
  }

  initDelete() {
    this.el.on("click", (ev) => {
      this.dataToModal(ev);
    });
  }

  dataToModal(ev) {
    const $button = $(ev.target).closest("button");
    const title = $button.attr("data-title");
    const id = $button.attr("data-id");
    const target = $button.attr("data-target");
    const toggle = $button.attr("data-toggle");
    const modalTitle = title ? `Delete - ${title}` : "Delete";
    const $deleteModal = $(document).find(`.modal--delete${target}`);

    try {
      if (!id || !target || !toggle) {
        throw "Delete button should have data attributes id, toggle and target!";
      } else if ($deleteModal.length === 0) {
        throw `There is no modal with id: ${target}`;
      }
    } catch (e) {
      logging.error(e);
      this.el.on("click", function (e) {
        e.stopPropagation();
      });
    }

    $deleteModal.find(".modal-title").text(modalTitle);
    $deleteModal.find("button[type=submit]").val(id);
  }
}

export default DeleteButtonComponent;
