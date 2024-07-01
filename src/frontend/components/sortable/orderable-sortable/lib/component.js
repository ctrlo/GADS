import { Component } from "component";

class OrderableSortableComponent extends Component {
    constructor(element)  {
        super(element);
        this.el = $(this.element);
        this.selectElement = this.el.find(".select__menu-item");

        this.initSortable();
    }

    initSortable() {
      this.selectElement.on("click", (ev) => { this.handleOrder(ev); } );
    }

    handleOrder(ev) {
      const target = $(ev.currentTarget);

      if (target.data("value") === 2) {
        this.orderRows(true);
      } else if (target.data("value") === 3) {
        this.orderRows(false);
      }
    }

    orderRows(ascending) {
      const items = $(".sortable__list").children(".sortable__row").sort(function(a, b) {
        const vA = $(".input > .input__field > .form-control", a).val();
        const vB = $(".input > .input__field > .form-control", b).val();
        if (ascending) {
          return (vA < vB) ? -1 : (vA > vB) ? 1 : 0;
        } else {
          return (vA > vB) ? -1 : (vA < vB) ? 1 : 0;
        }
      });
      $(".sortable__list").append(items);
    }
}

export default OrderableSortableComponent;
