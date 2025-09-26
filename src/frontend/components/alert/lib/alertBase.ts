import { Hidable, Renderable } from 'util/renderable';
import { AlertType } from './types';

export abstract class AlertBase extends Hidable implements Renderable<HTMLDivElement> {
    /**
     * Create an instance of AlertBase.
     * This class serves as a base for alert components.
     * It implements the Renderable interface, which requires a render method.
     * The render method should be implemented by subclasses to provide specific rendering logic.
     * @implements {Renderable<HTMLDivElement>}
     * @param {string} message - The message to be displayed in the alert.
     * @param {AlertType} type - The type of alert, which determines its styling and behavior.
     * @see Renderable
     * @see Hidable
     * @see AlertType
     * @example
     * const alert = new AlertBase('This is an alert message', AlertType.INFO);
     * document.body.appendChild(alert.render());
     */
    constructor(private readonly message: string, private readonly type: AlertType, private readonly transparent: boolean = false) {
        super();
    }

    /**
     * Render the alert as an HTMLDivElement.
     * @returns {HTMLDivElement} The rendered HTML element representing the alert.
     */
    render(): HTMLDivElement {
        if(this.element) throw new Error('AlertBase.render() should not be called multiple times without resetting the element.');
        const alertDiv = document.createElement('div');
        alertDiv.classList.add('alert', `alert-${this.type}`);
        if(this.transparent) {
            alertDiv.classList.add('alert-no-bg');
        }
        for(const item of this.message.split('\n')) {
            const pDiv = document.createElement('p');
            pDiv.textContent = item;
            alertDiv.appendChild(pDiv);
        }
        this.element = alertDiv;
        return alertDiv;
    }
}
