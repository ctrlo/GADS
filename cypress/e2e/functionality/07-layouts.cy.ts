import { LUA } from "../../../src/frontend/js/lib/util/formatters/lua";
import { LayoutBuilder } from "../../support/builders/layout/LayoutBuilder";
import { ICodeLayoutBuilder, ICurvalLayoutBuilder, IDropdownLayoutBuilder, ILayoutBuilder } from "../../support/builders/layout/interfaces";
import { goodPassword, goodUser } from "../../support/constants";

describe("Layout creation tests", () => {
    const refShortName = "tr";

    beforeEach(() => {
        cy.login(goodUser, goodPassword);
    });

    context("Simple layout creation", () => {
        ["TEXT", "INTEGER", "DATE", "DATE-RANGE", "DOCUMENT", "PERSON", "TREE"].forEach((layoutType) => {
            it(`Should create ${layoutType} layout`, () => {
                const builder:ILayoutBuilder = LayoutBuilder.create(<any>layoutType) as ILayoutBuilder;
                builder
                    .withName("test1")
                    .withShortName("t1");
                cy.createLayout(builder, true);
                builder.checkField();
            });
        });

        afterEach(() => {
            cy.deleteLayoutByShortName("t1", true);
        });
    });

    context("Layout creation with code", () => {
        it("Should error on creating a RAG layout with invalid code", () => {
            const refField = LayoutBuilder.create("TEXT");
            refField.withName("refField").withShortName(refShortName);
            const builder:ICodeLayoutBuilder = LayoutBuilder.create("RAG") as ICodeLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .withCode(LUA`
function beepbeep(${refShortName})
    return ${refShortName}
end
        `);
            cy.createLayout(refField, true);
            refField.checkField();
            cy.createLayout(builder, true);

            cy.get(".alert-danger")
                .contains("Invalid code")
                .should("be.visible");

            //As the layouts aren't consistent across tests, we need to delete them manually rather than afterEach
            cy.get("a")
                .contains("Cancel")
                .click();

            cy.deleteLayoutByShortName(refShortName, true);
        });

        it("Should create a RAG layout with valid code", () => {
            const refField = LayoutBuilder.create("TEXT");
            refField.withName("refField").withShortName(refShortName);
            const builder:ICodeLayoutBuilder = LayoutBuilder.create("RAG") as ICodeLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .withCode(LUA`
function evaluate(${refShortName})
    return "red";
end
        `);
            cy.createLayout(refField, true);
            refField.checkField();
            cy.createLayout(builder, true);
            builder.checkField();

            //As the layouts aren't consistent across tests, we need to delete them manually rather than afterEach
            cy.deleteLayoutByShortName("t1", true);
            cy.deleteLayoutByShortName(refShortName, true);
        });

        it("Should error on creating a CALC layout with invalid code", () => {
            const refField = LayoutBuilder.create("TEXT");
            refField.withName("refField").withShortName(refShortName);
            const builder:ICodeLayoutBuilder = LayoutBuilder.create("CALC") as ICodeLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .withCode(LUA`
function beepboop()
    return ${refShortName}
end
        `);
            cy.createLayout(refField, true);
            refField.checkField();
            cy.createLayout(builder, true);
            cy.get(".alert-danger").contains("Invalid code");

            //As the layouts aren't consistent across tests, we need to delete them manually rather than afterEach
            cy.deleteLayoutByShortName(refShortName, true);
        });

        it("Should create a CALC layout with valid code", () => {
            const refField = LayoutBuilder.create("TEXT");
            refField.withName("refField").withShortName(refShortName);
            const builder:ICodeLayoutBuilder = LayoutBuilder.create("CALC") as ICodeLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .withCode(LUA`
function evaluate (${refShortName})
    return ${refShortName}
end
        `);
            cy.createLayout(refField, true);
            refField.checkField();
            cy.createLayout(builder, true);
            builder.checkField();

            //As the layouts aren't consistent across tests, we need to delete them manually rather than afterEach
            cy.deleteLayoutByShortName("t1", true);
            cy.deleteLayoutByShortName(refShortName, true);
        });
    });

    context("Layout creation with dropdown", () => {
        it("Creates a dropdown", () => {
            const builder:IDropdownLayoutBuilder = LayoutBuilder.create("DROPDOWN") as IDropdownLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .addOption("Option 1")
                .addOption("Option 2")
                .addOption("Option 3");
            cy.createLayout(builder, true);
            builder.checkField();
        })

        afterEach(() => {
            cy.deleteLayoutByShortName("t1", true);
        });
    });

    context("Layout creation with Curval", ()=>{
        it("Creates a Curval with reference", ()=>{
            const refName = "refField";
            const refTable = "curval";
            // Create reference table
            cy.createInstance(refTable)
            cy.gotoInstanceByShortName(refTable, "layout")
            // Create reference field in reference table
            const refField = LayoutBuilder.create("TEXT")
                .withName(refName)
                .withShortName(refName)
            cy.createLayout(refField)
            // Go to table1
            cy.gotoInstanceByShortName("table1", "layout")
            // Create curval field with reference to reference field
            const builder:ICurvalLayoutBuilder = LayoutBuilder.create("CURVAL") as ICurvalLayoutBuilder;
            builder
                .withName("test1")
                .withShortName("t1")
                .withReference("curval")
                .withField(refName);
            // Check the field exists and doesn't error
            cy.createLayout(builder);
            builder.checkField();
            
            // Delete the field
            cy.gotoInstanceByShortName("table1", "layout");
            cy.deleteLayoutByShortName("t1");
            // Delete the reference field
            cy.gotoInstanceByShortName(refTable, "layout");
            cy.deleteLayoutByShortName(refName);
            cy.deleteInstanceByShortName(refTable);
        });
    });
});
