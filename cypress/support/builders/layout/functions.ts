import { LayoutType } from "./types";

function translateLayoutToDropdown(type: LayoutType) {
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
        case "CURVAL": return "Record from other data sheet";
        case "AUTOCUR": return "autocur";
        default: throw new Error("Invalid layout type");
    }
}

export { translateLayoutToDropdown, translateLayoutType }