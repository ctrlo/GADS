import { Component } from 'component';
import { CalculatorOperation } from './CalculatorOperation';

/**
 * CalculatorComponent class to handle calculator functionality in the UI.
 * It initializes a calculator dropdown for input fields, allowing users to perform basic arithmetic operations.
 */
class CalculatorComponent extends Component {
    /**
     * Creates an instance of CalculatorComponent.
     * @param {HTMLElement} element The element to be initialized as a calculator component.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);

        this.initCalculator();
    }

    /**
     * Array of CalculatorOperation instances representing basic arithmetic operations.
     * Each operation includes an action name, label, keypresses, and a function to perform the operation.
     * This array is used to dynamically create buttons and handle operations in the calculator UI.
     * @static
     * @type {CalculatorOperation[]}
     * @readonly
     */
    calculatorActions = [
        new CalculatorOperation(
            'add',
            '+',
            ['+'],
            (a, b) => a + b
        ),
        new CalculatorOperation(
            'subtract',
            '-',
            ['-'],
            (a, b) => a - b
        ),
        new CalculatorOperation(
            'multiply',
            '×',
            ['*', 'X', 'x', '×'],
            (a, b) => a * b
        ),
        new CalculatorOperation(
            'divide',
            '÷',
            ['/', '÷'],
            (a, b) => a / b
        )
    ];

    /**
     * Initializes the calculator functionality by creating a dropdown
     * with buttons for arithmetic operations and an input field for numbers.
     */
    initCalculator() {
        const selector = this.el.find('input:not([type="checkbox"])');
        const $nodes = this.el.find('label:not(.checkbox-label)');

        $nodes.each((i, node) => {
            const $el = $(node);
            const calculator_id = 'calculator_div';
            const calculator_elem = $(`<div class="calculator-dropdown dropdown-menu" id="${calculator_id}"></div>`);

            calculator_elem.css({
                position: 'absolute',
                'z-index': 1100,
                display: 'none',
                padding: '10px'
            });

            $('body').append(calculator_elem);

            calculator_elem.append(
                '<form class="form-inline">' +
                '    <div class="form-group"><div class="radio-group radio-group--buttons" data-toggle="buttons"></div></div>' +
                '    <div class="form-group"><div class="input"><input type="text" placeholder="Number" class="form-control"></input></div></div>' +
                '    <div class="form-group">' +
                '        <input type="submit" value="Calculate" class="btn btn-default"></input>' +
                '    </div>' +
                '</form>'
            );

            $(document).on('mouseup', (e) => {
                if (
                    !calculator_elem.is(e.target) &&
                    calculator_elem.has(e.target).length === 0
                ) {
                    calculator_elem.hide();
                }
            });

            let calculator_operation;
            let integer_input_elem;

            const keypress_action = {};
            const operator_btns_elem = calculator_elem.find('.radio-group--buttons');

            $(this.calculatorActions).each((i) => {
                const btn = this.calculatorActions[i];
                const button_elem = btn.render();
                operator_btns_elem.append(button_elem);

                $(button_elem).find('.radio-group__label')
                    .on('click', () => {
                        $(button_elem).find('.radio-group__input')
                            .prop('checked', true);
                        calculator_operation = btn.operation;
                        calculator_elem.find(':text').trigger('focus');
                    });

                for (const j in btn.keypress) {
                    const keypress = btn.keypress[j];
                    keypress_action[keypress] = btn.action;
                }
            });

            calculator_elem.find(':text').on('keypress', (e) => {
                const key_pressed = e.key;

                if (key_pressed in keypress_action) {
                    const button_selector = `.btn_label_${keypress_action[key_pressed]}`;
                    calculator_elem.find(button_selector).trigger('click');
                    e.preventDefault();
                }
            });

            calculator_elem.find('form').on('submit', (e) => {
                const new_value = calculator_operation(
                    +integer_input_elem.val(),
                    +calculator_elem.find(':text').val()
                );

                integer_input_elem.val(new_value);
                calculator_elem.hide();
                e.preventDefault();
            });

            const $calc_button = $('<span class="btn btn-link openintcalculator">Calculator</span>');

            $calc_button.insertAfter($el).on('click', (e) => {
                const calc_elem = $(e.target);
                const container_elem = calc_elem.closest('.form-group');
                const input_elem = container_elem.find(selector);

                const container_y_offset = container_elem.offset().top;
                const container_height = container_elem.height();
                const calc_div_height = $('#calculator_div').height();
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

                const calc_input = calculator_elem.find(':text');
                calc_input.val('');
                calculator_elem.show();
                calc_input.trigger('focus');
                integer_input_elem = input_elem;
            });
        });
    }
}

export default CalculatorComponent;
