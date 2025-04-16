import { Component } from 'component'

/**
 * Calculator component for number input fields.
 */
class CalculatorComponent extends Component {
  /**
   * Create a new CalculatorComponent instance.
   * @param {HTMLElement} element The element to attach the calculator to.
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)

    this.initCalculator()
  }

  /**
   * Initialize the calculator component.
   */
  initCalculator() {
    this.selector = this.el.find('input:not([type="checkbox"])')
    const $nodes = this.el.find('label:not(.checkbox-label)')

    $nodes.each((i, node) => {
      const calculator_elem = this.createCalcElement();

      $('body').append(calculator_elem);
      this.setupEvents(calculator_elem);
      this.setupShowButton($(node), calculator_elem);
    })
  }

  /**
   * Set up the show button for the calculator
   * @param {JQuery<HTMLElement>} $node The node to attach the calculator to
   * @param {JQuery<HTMLElement>} $calculator The calculator element
   * @private
   */
  setupShowButton($node, $calculator) {
    const calc_button = document.createElement('span');
    calc_button.classList.add('btn');
    calc_button.classList.add('btn-link');
    calc_button.classList.add('openintcalculator');
    calc_button.innerText = 'Calculator';

    const $calc_button = $(calc_button)

    $calc_button.insertAfter($node).on('click', (e) => {
      const calc_elem = $(e.target)
      const container_elem = calc_elem.closest('.form-group')
      const input_elem = container_elem.find(this.selector)

      const container_y_offset = container_elem.offset().top
      const container_height = container_elem.height()
      const calc_div_height = $('#calculator_div').height()
      let calculator_y_offset

      if (container_y_offset > calc_div_height) {
        calculator_y_offset = container_y_offset - calc_div_height
      } else {
        calculator_y_offset = container_y_offset + container_height
      }

      $calculator.css({
        top: calculator_y_offset,
        left: container_elem.offset().left
      })

      const calc_input = $calculator.find(':text')
      calc_input.val('')
      $calculator.show()
      calc_input.trigger("focus")
      this.integer_input_elem = input_elem
    })
  }

  /**
   * Set up the events for the calculator
   * @param {JQuery<HTMLElement>} $target The target element to attach the events to
   * @private
   */
  setupEvents($target) {
    const keypress_action = this.setupButtons($target)

    $(document).on('mouseup', (e) => {
      if (
        !$target.is(e.target) &&
        $target.has(e.target).length === 0
      ) {
        $target.hide()
      }
    })

    $target.find(':text').on('keypress', (e) => {
      const key_pressed = e.key

      if (key_pressed in keypress_action) {
        const button_selector = `.btn_label_${keypress_action[key_pressed]}`
        $target.find(button_selector).trigger("click")
        // I think I've missed something here, it doesn't trigger the click as expected here
        this.calculator_operation = this.buttons.find(b => b.action === keypress_action[key_pressed]).operation
        e.preventDefault()
      } else if (key_pressed === 'Enter') {
        $target.find('button').trigger("click")
        e.preventDefault()
      }
    })

    $target.find('button').on('click', (e) => {
      const new_value = this.calculator_operation(
        +this.integer_input_elem.val(),
        +$target.find(':text').val()
      )

      this.integer_input_elem.val(new_value)
      $target.hide()
      e.preventDefault()
    })
  }

  /**
   * Create the calculator buttons
   * @returns {{action: string, label: string, keypress: string[], operation: (function(number, number): number)}[]} The calculator button definitions
   * @private
   */
  get buttons() {
    return [
      {
        action: 'add',
        label: '+',
        keypress: ['+'],
        operation: function (a, b) {
          return a + b
        }
      },
      {
        action: 'subtract',
        label: '-',
        keypress: ['-'],
        operation: function (a, b) {
          return a - b
        }
      },
      {
        action: 'multiply',
        label: '×',
        keypress: ['*', 'X', 'x', '×'],
        operation: function (a, b) {
          return a * b
        }
      },
      {
        action: 'divide',
        label: '÷',
        keypress: ['/', '÷'],
        operation: function (a, b) {
          return a / b
        }
      }
    ];
  }

  /**
   * Create the base calculator element
   * @returns {JQuery<HTMLElement>} The calculator element
   * @private
   */
  createCalcElement() {
    const calculator_id = 'calculator_div'

    const calculator_elem = document.createElement('div')
    calculator_elem.id = calculator_id
    calculator_elem.classList.add('calculator-dropdown')
    calculator_elem.classList.add('dropdown-menu')

    $(calculator_elem).css({
      position: 'absolute',
      'z-index': 1100,
      display: 'none',
      padding: '10px'
    })

    const formElement = document.createElement('form');
    formElement.classList.add('form-inline');

    const radioFormGroupElement = document.createElement('div');
    radioFormGroupElement.classList.add('form-group');

    const radioGroupElement = document.createElement('div');
    radioGroupElement.classList.add('radio-group');
    radioGroupElement.classList.add('radio-group--buttons');
    radioGroupElement.setAttribute('data-toggle', 'buttons');
    radioFormGroupElement.appendChild(radioGroupElement);

    const inputFormGroupElement = document.createElement('div');
    inputFormGroupElement.classList.add('form-group');

    const inputElement = document.createElement('div');
    inputElement.classList.add('input');

    const input = document.createElement('input');
    input.setAttribute('type', 'text');
    input.setAttribute('placeholder', 'Number');
    input.classList.add('form-control');
    inputElement.appendChild(input);
    inputFormGroupElement.appendChild(inputElement);

    const submitFormGroupElement = document.createElement('div');
    submitFormGroupElement.classList.add('form-group');

    const button = document.createElement('button');
    button.type = 'button';
    button.classList.add('btn');
    button.classList.add('btn-default');
    button.innerText = 'Calculate';
    submitFormGroupElement.appendChild(button);

    formElement.appendChild(radioFormGroupElement);
    formElement.appendChild(inputFormGroupElement);
    formElement.appendChild(submitFormGroupElement);
    calculator_elem.append(formElement);

    return $(calculator_elem);
  }

  /**
   * Set up the buttons for the calculator
   * @param {JQuery<HTMLElement>} $element The element to attach the buttons to
   * @returns {{[key:string]:string}} A map of the keys and their corresponding actions
   * @private
   */
  setupButtons($element) {
    let keypress_action = {}

    const operator_btns_elem = $element.find('.radio-group--buttons')

    for (const btn of this.buttons) {
      const button_elem = document.createElement('div')
      button_elem.classList.add('radio-group__option')

      const input = document.createElement('input')
      input.type = 'radio';
      input.name = 'op';
      input.id = `op_${btn.action}`;
      input.classList.add('radio-group__input');
      input.classList.add(`btn_label_${btn.action}`);

      const label = document.createElement('label')
      label.classList.add('radio-group__label');
      label.setAttribute('for', `op_${btn.action}`);
      label.innerText = btn.label;

      button_elem.appendChild(input)
      button_elem.appendChild(label)

      operator_btns_elem.append(button_elem)

      $(button_elem).find('.radio-group__label').on('click', () => {
        $(button_elem).find('.radio-group__input').prop("checked", true)
        this.calculator_operation = btn.operation
        $element.find(':text').trigger("focus")
      })

      for (const j in btn.keypress) {
        const keypress = btn.keypress[j]
        keypress_action[keypress] = btn.action
      }
    }

    return keypress_action;
  }
}

export default CalculatorComponent
