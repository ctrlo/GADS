import { Component } from "component";

class CalculatorComponent extends Component {
  constructor(element)  {
    super(element);
    this.el = $(this.element);

    this.initCalculator();
  }

  initCalculator() {
    const selector = this.el.find("input:not([type=\"checkbox\"])");
    const $nodes = this.el.find("label:not(.checkbox-label)");

    $nodes.each((i, node) => {
      const $el = $(node);
      const calculator_id = "calculator_div";
      const calculator_elem = $(`<div class="calculator-dropdown dropdown-menu" id="${calculator_id}"></div>`);

      calculator_elem.css({
        position: "absolute",
        "z-index": 1100,
        display: "none",
        padding: "10px"
      });

      $("body").append(calculator_elem);

      calculator_elem.append(
        "<form class=\"form-inline\">" +
          "    <div class=\"form-group\"><div class=\"radio-group radio-group--buttons\" data-toggle=\"buttons\"></div></div>" +
          "    <div class=\"form-group\"><div class=\"input\"><input type=\"text\" placeholder=\"Number\" class=\"form-control\"></input></div></div>" +
          "    <div class=\"form-group\">" +
          "        <input type=\"submit\" value=\"Calculate\" class=\"btn btn-default\"></input>" +
          "    </div>" +
          "</form>"
      );

      $(document).on("mouseup",(e) => {
        if (
          !calculator_elem.is(e.target) &&
          calculator_elem.has(e.target).length === 0
        ) {
          calculator_elem.hide();
        }
      });

      let calculator_operation;
      let integer_input_elem;

      const calculator_button = [
        {
          action: "add",
          label: "+",
          keypress: ["+"],
          operation: function(a, b) {
            return a + b;
          }
        },
        {
          action: "subtract",
          label: "-",
          keypress: ["-"],
          operation: function(a, b) {
            return a - b;
          }
        },
        {
          action: "multiply",
          label: "×",
          keypress: ["*", "X", "x", "×"],
          operation: function(a, b) {
            return a * b;
          }
        },
        {
          action: "divide",
          label: "÷",
          keypress: ["/", "÷"],
          operation: function(a, b) {
            return a / b;
          }
        }
      ];
      const keypress_action = {};
      const operator_btns_elem = calculator_elem.find(".radio-group--buttons");

      $(calculator_button).each((i) => {
        const btn = calculator_button[i];
        const button_elem = $(
          "<div class=\"radio-group__option\">" +
            `<input type="radio" name="op" id="op_${btn.action}" class="radio-group__input btn_label_${btn.action}">` +
            `<label class="radio-group__label" for="op_${btn.action}">${btn.label}</label>` +
          "</div>"
        );

        operator_btns_elem.append(button_elem);

        $(button_elem).find(".radio-group__label").on("click", () => {
          $(button_elem).find(".radio-group__input").prop("checked", true);
          calculator_operation = btn.operation;
          calculator_elem.find(":text").focus();
        });

        for (const j in btn.keypress) {
          const keypress = btn.keypress[j];
          keypress_action[keypress] = btn.action;
        }
      });

      calculator_elem.find(":text").on("keypress", (e) => {
        const key_pressed = e.key;

        if (key_pressed in keypress_action) {
          const button_selector = `.btn_label_${keypress_action[key_pressed]}`;
          calculator_elem.find(button_selector).trigger("click");
          e.preventDefault();
        }
      });

      calculator_elem.find("form").on("submit", (e) => {
        const new_value = calculator_operation(
          +integer_input_elem.val(),
          +calculator_elem.find(":text").val()
        );

        integer_input_elem.val(new_value);
        calculator_elem.hide();
        e.preventDefault();
      });

      const $calc_button = $("<span class=\"btn btn-link openintcalculator\">Calculator</span>");

      $calc_button.insertAfter($el).on("click", (e) => {
        const calc_elem = $(e.target);
        const container_elem = calc_elem.closest(".form-group");
        const input_elem = container_elem.find(selector);

        const container_y_offset = container_elem.offset().top;
        const container_height = container_elem.height();
        const calc_div_height = $("#calculator_div").height();
        let calculator_y_offset;

        if (container_y_offset > calc_div_height) {
          calculator_y_offset = container_y_offset - calc_div_height;
        } else {
          calculator_y_offset = container_y_offset + container_height;
        }

        calculator_elem.css({
          top: calculator_y_offset,
          left: container_elem.offset().left
        });

        const calc_input = calculator_elem.find(":text");
        calc_input.val("");
        calculator_elem.show();
        calc_input.trigger("focus");
        integer_input_elem = input_elem;
      });
    });
  }
}

export default CalculatorComponent;
