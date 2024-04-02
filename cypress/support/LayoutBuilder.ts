/// <reference types="cypress" />

import { LUACode } from "../../src/frontend/js/lib/util/formatters/lua";

type LayoutType = "TEXT" | "INTEGER" | "DATE" | "DATE-RANGE" | "DROPDOWN" | "TREE" | "DOCUMENT" | "PERSON" | "RAG" | "CALC" | "CURVAL" | "AUTOCUR";

export interface IBuildable {
    build(): void;
}

export class LayoutBuilder {
    public static create(layoutType: LayoutType): BasicLayoutBuilder | CodeLayoutBuilder | DropdownLayoutBuilder | CurvalLayoutBuilder {
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

function translateLayoutToDropdown(type:LayoutType) {
    switch (type) {
        case "TEXT": return "Text";
        case "INTEGER": return "Integer";
        case "DATE": return "Date";
        case "DATE-RANGE": return "Date range";
        case "DROPDOWN": return "Dropdown list";
        case "TREE": return "Tree";
        case "DOCUMENT": return "Document";
        case "PERSON": return "Person";
        case "RAG": return "RedAmberGreen status (RAG)";
        case "CALC": return "Calculated value";
        case "CURVAL": return "Field(s) for records from another table";
        case "AUTOCUR": return "Automatic value of other sheet's references to this one";
        default: throw new Error("Invalid layout type");
    }
}

function translateLayoutType(type: LayoutType) {
    switch (type) {
        case "TEXT": return "Text";
        case "INTEGER": return "Integer";
        case "DATE": return "Date";
        case "DATE-RANGE": return "Date range";
        case "DROPDOWN": return "Select";
        case "TREE": return "Tree";
        case "DOCUMENT": return "File";
        case "PERSON": return "Person";
        case "RAG": return "RedAmberGreen (RAG) status";
        case "CALC": return "Calculated value";
        case "CURVAL": return "curval";
        case "AUTOCUR": return "autocur";
        default: throw new Error("Invalid layout type");
    }
};

abstract class LayoutBuilderBase implements IBuildable {
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

    build(): void {
        cy.visit("http://localhost:3000/table");
        cy.getDataTable()
            .find("tbody")
            .find("tr").first()
            .find("a").contains("Edit table")
            .click();
        cy.get("a")
            .contains("Fields")
            .click();
        cy.get("a")
            .contains("Add a field")
            .click();
        cy.get("input[name='name']")
            .type(this.name);
        this.setType();
        if (this.shortName) {
            cy.get("button")
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
        cy.get("button")
            .contains("Permissions")
            .click();
        cy.getDataTable()
            .find("input[type=checkbox]")
            .click({ multiple: true, force: true });
    }
}

class BasicLayoutBuilder extends LayoutBuilderBase {
    constructor(type: LayoutType) {
        super(type);
    }

    buildSpecific() {
        // NOOP: This is a basic layout
    }
}

class CodeLayoutBuilder extends LayoutBuilderBase {
    private code: LUACode;

    constructor(type: LayoutType) {
        super(type);
    }

    withCode(code: LUACode) {
        this.code = code;
    }

    buildSpecific() {
        // Expand the code editor
        if (this.layoutType === "RAG") {
            cy.get("button")
                .contains("Field settings for RAG")
                .click();
            // Enter the code
            cy.get("textarea[name='code_rag']")
                .type(this.code);
        } else if (this.layoutType === "CALC") {
            cy.get("button")
                .contains("Field settings for calculated value")
                .click();
            cy.get("textarea[name='code_calc']")
                .type(this.code);
        } else {
            throw new Error("Invalid layout type");
        }
    }
}


class DropdownLayoutBuilder extends LayoutBuilderBase {
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
        cy.get("button")
            .contains("Field settings for dropdown list")
            .click();
        // Enter the options
        for(let i; i<this.options.values.length-1; i++) {
            cy.get("input[name='enumval']")
                .type(this.options[i]);
            cy.get("button")
                .contains("Add a value")
                .click();
        }
        cy.get("input[name='enumval']")
            .type(this.options[this.options.length-1]);
    }
}

class CurvalLayoutBuilder extends LayoutBuilderBase {
    private reference: number;
    private field: string;

    constructor() {
        super("CURVAL");
    }

    withReference(reference: number) {
        this.reference = reference;
    }

    withField(field: string) {
        this.field = field;
    }

    buildSpecific() {
        // Expand the options
        // Enter the options
    }

    checkField(): void {
        // Check the field is present
        // Check the field is of the correct type
    }
}
