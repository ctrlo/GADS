/// <reference types="cypress" />

import { LUACode } from "../../../../src/frontend/js/lib/util/formatters/lua";
import { ICodeLayoutBuilder, ICurvalLayoutBuilder, IDropdownLayoutBuilder, ILayoutBuilder } from "./interfaces";
import { translateLayoutToDropdown, translateLayoutType } from "./functions";
import { LayoutType } from "./types";

export class LayoutBuilder {
    public static create(layoutType: LayoutType) {
        switch (layoutType) {
            case "TEXT":
            case "INTEGER":
            case "DATE":
            case "DATE-RANGE":
            case "DOCUMENT":
            case "PERSON":
            case "TREE":
                return new BasicLayoutBuilder(layoutType);
            case "RAG":
            case "CALC":
                return new CodeLayoutBuilder(layoutType);
            case "DROPDOWN":
                return new DropdownLayoutBuilder();
            case "CURVAL":
                return new CurvalLayoutBuilder();
            case "AUTOCUR":
            default:
                throw new Error("Invalid layout type");
        }
    }
}

abstract class LayoutBuilderBase implements ILayoutBuilder {
    protected name: string;
    protected shortName?: string;
    protected layoutType: LayoutType;

    constructor(type: LayoutType) {
        this.layoutType = type;
    }

    withName(name: string) {
        this.name = name;
        return this;
    }

    withShortName(shortname?: string) {
        this.shortName = shortname;
        return this;
    }

    build(navigate:boolean = false): void {
        if (navigate) {
            cy.visit("http://localhost:3000/table");
            cy.getDataTable()
                .find("tbody")
                .find("tr").first()
                .find("a").contains("Edit table")
                .click();
            cy.get("a")
                .contains("Fields")
                .click();
        }
        cy.get("a")
            .contains("Add a field")
            .click();
        cy.get("input[name='name']")
            .type(this.name);
        this.setType();
        if (this.shortName) {
            cy.get("span")
                .contains("Advanced settings")
                .click();
            cy.get("input[name='name_short']")
                .type(this.shortName);
        }
        this.buildSpecific();
        this.setPermissions();
        cy.on("uncaught:exception", (err) => {
            if(err.message.includes("filters")) return false;
            return true;
        })
        cy.get("button[type='submit']")
            .contains("Save")
            .click();
    }

    protected abstract buildSpecific(): void;

    checkField(): void {
        cy.getDataTable().find("tbody").find("tr").contains(this.name);
        cy.getDataTable().find("tbody").find("tr").contains(translateLayoutType(this.layoutType));
    }

    protected setType(): void {
        cy.get('#btn-field_type')
            .click();
        cy.get("li")
            .contains(translateLayoutToDropdown(this.layoutType))
            .click();
    }

    protected setPermissions(): void {
        cy.get("span")
            .contains("Permissions")
            .click();
        cy.getDataTable()
            .find("input[type=checkbox]")
            .click({ multiple: true, force: true });
    }
}

class BasicLayoutBuilder extends LayoutBuilderBase implements ILayoutBuilder {
    constructor(type: LayoutType) {
        super(type);
    }

    buildSpecific() {
        // NOOP: This is a basic layout
    }
}

class CodeLayoutBuilder extends LayoutBuilderBase implements ICodeLayoutBuilder {
    private code: LUACode;

    constructor(type: LayoutType) {
        super(type);
    }

    withCode(code: LUACode) {
        this.code = code;
        return this;
    }

    buildSpecific() {
        // Expand the code editor
        if (this.layoutType === "RAG") {
            cy.get("span")
                .contains("Field settings for RAG")
                .click();
            // Enter the code
            cy.get("textarea[name='code_rag']")
                .type(this.code);
        } else if (this.layoutType === "CALC") {
            cy.get("span")
                .contains("Field settings for calculated value")
                .click();
            cy.get("textarea[name='code_calc']")
                .type(this.code);
            cy.get("#btn-show_in_edit")
                .click();
            cy.get("li")
                .contains("Yes")
                .click();
        } else {
            throw new Error("Invalid layout type");
        }
    }
}


class DropdownLayoutBuilder extends LayoutBuilderBase implements IDropdownLayoutBuilder {
    private options: string[];

    constructor() {
        super("DROPDOWN");
        this.options = [];
    }

    addOption(option: string) {
        this.options.push(option);
        return this;
    }

    buildSpecific() {
        // Expand the options
        cy.get("span")
            .contains("Field settings for dropdown list")
            .click();
        // Enter the options
        for(let i=0; i<this.options.length-1; i++) {
            cy.get("input[name='enumval']")
                .last()
                .type(this.options[i]);
            cy.get("button")
                .contains("Add a value")
                .click();
        }
        cy.get("input[name='enumval']")
            .last()
            .type(this.options[this.options.length-1]);
    }
}

class CurvalLayoutBuilder extends LayoutBuilderBase implements ICurvalLayoutBuilder {
    private reference: string;
    private field: string;

    constructor() {
        super("CURVAL");
    }

    withReference(reference: string) {
        this.reference = reference;
        return this;
    }

    withField(field: string) {
        this.field = field;
        return this;
    }

    buildSpecific() {
        // Expand Field settings
        cy.get("span")
            .contains("Field settings for fields from another table")
            .click();
        // Enter the options
        cy.get("button#btn-refers_to_instance_id")
            .click();
        cy.get("li[role='option']")
            .contains(this.reference)
            .click();
        cy.get("label")
            .contains(this.field)
            .click();
        cy.get("button.btn-sm[data-delete='rule']")
            .eq(1)
            .click();
        //Someone owes me a drink!
    }
}
