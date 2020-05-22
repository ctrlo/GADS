var setupCalculator = function(context) {
  var selector = ".intcalculator";
  var $nodes = $(".fileupload", context);
  $nodes = $(selector, context)
    .closest(".form-group")
    .find("label");

  $nodes.each(function() {
    var $el = $(this);
    var calculator_id = "calculator_div";
    var calculator_elem = $(
      '<div class="dropdown-menu" id="' + calculator_id + '"></div>'
    );
    calculator_elem.css({
      position: "absolute",
      "z-index": 1100,
      display: "none",
      padding: "10px"
    });
    $("body").append(calculator_elem);

    calculator_elem.append(
      '<form class="form-inline">' +
        '    <div class="form-group btn-group operator" data-toggle="buttons"></div>' +
        '    <div class="form-group"><input type="text" placeholder="Number" class="form-control"></input></div>' +
        '    <div class="form-group">' +
        '        <input type="submit" value="Calculate" class="btn btn-default"></input>' +
        "    </div>" +
        "</form>"
    );

    $(document).mouseup(function(e) {
      if (
        !calculator_elem.is(e.target) &&
        calculator_elem.has(e.target).length === 0
      ) {
        calculator_elem.hide();
      }
    });

    var calculator_operation;
    var integer_input_elem;

    var calculator_button = [
      {
        action: "add",
        subvaluelabel: "+",
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
    var keypress_action = {};
    var operator_btns_elem = calculator_elem.find(".operator");
    for (var i in calculator_button) {
      (function() {
        var btn = calculator_button[i];
        var button_elem = $(
          '<label class="btn btn-primary" style="width:40px">' +
            '<input type="radio" name="op" class="btn_label_' +
            btn.action +
            '">' +
            btn.label +
            "</input>" +
            "</label>"
        );
        operator_btns_elem.append(button_elem);
        button_elem.on("click", function() {
          calculator_operation = btn.operation;
          calculator_elem.find(":text").focus();
        });
        for (var j in btn.keypress) {
          var keypress = btn.keypress[j];
          keypress_action[keypress] = btn.action;
        }
      })();
    }

    calculator_elem.find(":text").on("keypress", function(e) {
      var key_pressed = e.key;
      if (key_pressed in keypress_action) {
        var button_selector = ".btn_label_" + keypress_action[key_pressed];
        calculator_elem.find(button_selector).click();
        e.preventDefault();
      }
    });
    calculator_elem.find("form").on("submit", function(e) {
      var new_value = calculator_operation(
        +integer_input_elem.val(),
        +calculator_elem.find(":text").val()
      );
      integer_input_elem.val(new_value);
      calculator_elem.hide();
      e.preventDefault();
    });

    var $calc_button = $(
      '<span class="btn-xs btn-link openintcalculator">Calculator</span>'
    );
    $calc_button.insertAfter($el).on("click", function(e) {
      var calc_elem = $(e.target);
      var container_elem = calc_elem.closest(".form-group");
      var input_elem = container_elem.find(selector);

      var container_y_offset = container_elem.offset().top;
      var container_height = container_elem.height();
      var calculator_y_offset;
      var calc_div_height = $("#calculator_div").height();
      if (container_y_offset > calc_div_height) {
        calculator_y_offset = container_y_offset - calc_div_height;
      } else {
        calculator_y_offset = container_y_offset + container_height;
      }
      calculator_elem.css({
        top: calculator_y_offset,
        left: container_elem.offset().left
      });
      var calc_input = calculator_elem.find(":text");
      calc_input.val("");
      calculator_elem.show();
      calc_input.focus();
      integer_input_elem = input_elem;
    });
  });
};

export { setupCalculator };
