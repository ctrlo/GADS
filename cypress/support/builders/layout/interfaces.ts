import { LUACode } from "../../../../src/frontend/js/lib/util/formatters/lua";

interface IBuildable {
    build(): void;
    build(navigate:boolean): void;
}

interface ILayoutBuilder extends IBuildable {
    withName(name: string): this;
    withShortName(shortname?: string): this;
    checkField(): void;
}

interface IDropdownLayoutBuilder extends ILayoutBuilder {
    addOption(option: string): this;
}

interface ICodeLayoutBuilder extends ILayoutBuilder {
    withCode(code: LUACode): this;
}

interface ICurvalLayoutBuilder extends ILayoutBuilder {
    withReference(reference: string): this;
    withField(field: string): this;
}

export { IBuildable, ILayoutBuilder, IDropdownLayoutBuilder, ICodeLayoutBuilder, ICurvalLayoutBuilder }