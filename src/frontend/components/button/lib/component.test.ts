import ButtonComponent from './component';

declare global {
    interface Window {
        $: JQueryStatic;
    }
}

export {}

window.$ = require('jquery');

describe("Button Component", () => {
    const buttonDefinitions = [
        {name: "report", class: "btn-js-report"},
        {name: "more info", class: "btn-js-more-info"},
        {name: "delete", class: "btn-js-delete"},
        {name: "submit field", class: "btn-js-submit-field"},
        {name: "add all fields", class: "btn-js-add-all-fields"},
        {name: "submit draft record", class: "btn-js-submit-draft-record"},
        {name: "submit record", class: "btn-js-submit-record"},
        {name: "save view", class: "btn-js-save-view"},
        {name: "show blank", class: "btn-js-show-blank"},
        {name: "curval remove", class: "btn-js-curval-remove"},
        {name: "remove unload", class: "btn-js-remove-unload"}
    ];

    it("should not create a button with an invalid type", () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn');
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses).toStrictEqual([]);
    });

    it("should not create a button with an invalid type but with valid class prefix", () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn-js-nope');
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses).toStrictEqual([]);
    });

    for(const buttonDefinition of buttonDefinitions) {
        it(`Should create a ${buttonDefinition.name} button`, () => {
            const buttonElement = document.createElement('button');
            buttonElement.classList.add(buttonDefinition.class);
            const button = new ButtonComponent(buttonElement);
            expect(button.linkedClasses.includes(buttonDefinition.class)).toBeTruthy();
        });
    }

    it("Should create a composite button", () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn-js-report');
        buttonElement.classList.add('btn-js-remove-unload');
        const button = new ButtonComponent(buttonElement);
        expect(button.linkedClasses.includes('btn-js-report')).toBeTruthy();
        expect(button.linkedClasses.includes('btn-js-remove-unload')).toBeTruthy();
    });
});