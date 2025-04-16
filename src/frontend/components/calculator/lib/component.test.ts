import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import Calculator from './component';

describe('Calculator', () => {
    beforeEach(() => {
        const formGroup = document.createElement('div');
        formGroup.classList.add('form-group');

        const div = document.createElement('div');
        div.classList.add('input', 'calculator')
        div.id = 'calculator';

        const labelDiv = document.createElement('div');
        labelDiv.classList.add('input__label');

        const label = document.createElement('label');
        label.setAttribute('for', 'input');
        labelDiv.appendChild(label);

        div.appendChild(labelDiv);

        const fieldDiv = document.createElement('div');
        fieldDiv.classList.add('input__field');

        const input = document.createElement('input');
        input.setAttribute('type', 'number');
        input.setAttribute('id', 'input');
        fieldDiv.appendChild(input);

        div.appendChild(fieldDiv);

        formGroup.appendChild(div);
        document.body.appendChild(formGroup);
    });

    afterEach(() => {
        document.body.innerHTML = '';
    });

    it('Should create a calculator with the relevant elements', () => {
        const div = document.getElementById('calculator') as HTMLElement;
        new Calculator(div);
        expect(div.dataset.componentInitializedCalculatorcomponent).toBe('true');
        const calcDiv = document.querySelector('#calculator_div');
        expect(calcDiv).not.toBeNull();
        const buttonLabels = ['add', 'subtract', 'multiply', 'divide'];
        for (const l of buttonLabels) {
            expect(calcDiv?.querySelector(`#op_${l}`)).not.toBeNull();
            expect(calcDiv?.querySelector(`[for="op_${l}"]`)).not.toBeNull();
        }
        expect($(calcDiv!).find(':text')).not.toBeNull();
        expect(calcDiv?.querySelector('button')).not.toBeNull();
    });

    for (const op of ['add', 'subtract', 'multiply', 'divide']) {
        it(`Should perform a ${op} operation`, () => {
            const values = [3, 2];
            let expected = 0;
            switch (op) {
                case 'add':
                    expected = values[0] + values[1];
                    break;
                case 'subtract':
                    expected = values[0] - values[1];
                    break;
                case 'multiply':
                    expected = values[0] * values[1];
                    break;
                case 'divide':
                    expected = values[0] / values[1];
                    break;
            }
            const div = document.getElementById('calculator') as HTMLElement;
            new Calculator(div);
            const calcDiv = document.querySelector('#calculator_div');
            const input = document.getElementById('input') as HTMLInputElement;
            expect(input).not.toBeNull();
            input.value = '3';
            const showButton = div.querySelector('span.openintcalculator') as HTMLSpanElement;
            expect(showButton).not.toBeNull();
            showButton.click();
            const add = calcDiv?.querySelector(`label[for=op_${op}]`) as HTMLLabelElement;
            expect(add).not.toBeNull();
            add.click();
            const value = $(calcDiv!).find<HTMLInputElement>(':text');
            expect(value).not.toBeNull();
            value.val('2');
            const button = calcDiv?.querySelector('button') as HTMLButtonElement;
            expect(button).not.toBeNull();
            button.click();
            expect(input.value).toBe(expected.toString());
        });
    }
});