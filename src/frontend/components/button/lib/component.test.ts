import "../../../testing/globals.definitions";
import ButtonComponent from './component';

describe("Button Component", () => {
    const buttonDefinitions = [
        { name: "report", class: "btn-js-report" },
        { name: "more info", class: "btn-js-more-info" },
        { name: "delete", class: "btn-js-delete" },
        { name: "submit field", class: "btn-js-submit-field" },
        { name: "add all fields", class: "btn-js-toggle-all-fields" },
        { name: "submit draft record", class: "btn-js-submit-draft-record" },
        { name: "submit record", class: "btn-js-submit-record" },
        { name: "save view", class: "btn-js-save-view" },
        { name: "show blank", class: "btn-js-show-blank" },
        { name: "curval remove", class: "btn-js-curval-remove" },
        { name: "remove unload", class: "btn-js-remove-unload" }
    ];

    it("should add a button definition", () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn-js-dynamic');
        const button = new ButtonComponent(buttonElement);
        expect(() => button.addDefinition({ className: 'btn-js-dynamic', importPath: './dynamic-button' })).not.toThrow();
    });

    it("should not add a button definition that already exists", () => {
        const buttonElement = document.createElement('button');
        buttonElement.classList.add('btn-js-dynamic');
        const button = new ButtonComponent(buttonElement);
        expect(() => button.addDefinition({ importPath: "./remove-unload-button.ts", className: "btn-js-remove-unload" })).toThrow(`Button definition for btn-js-remove-unload already exists`);
    });

    it("should not create a button with an invalid type", async () => {
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

    for (const buttonDefinition of buttonDefinitions) {
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
