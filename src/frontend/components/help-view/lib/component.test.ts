import HelpView from "./component";
import {describe, expect, it} from "@jest/globals";

class TestHelpView extends HelpView {
    public get button() {
        return this.$button;
    }
}

describe("help view tests", ()=> {
    it("throws an error when help-text is not provided", ()=> {
        const element = document.createElement("div");
        expect(()=>new HelpView(element)).toThrow("help-text is required");
    });

    it("throws when help-target is not provided", () =>{
        const element = document.createElement("div");
        element.setAttribute("data-help-text", "help text");
        expect(()=>new HelpView(element)).toThrow("help-target is required");
    });

    it("throws when help-target is not found", ()=>{
        const element = document.createElement("div");
        element.setAttribute("data-help-text", "help text");
        const helpTarget = "help-target";
        element.setAttribute("data-help-target", helpTarget);
        expect(()=>new HelpView(element)).toThrow(`Could not find help target with id: ${helpTarget}`);
    });

    it("links the help text to the help target", ()=>{
        const element = document.createElement("div");
        element.setAttribute("data-help-text", "help text");
        const helpTarget = "help-target";
        element.setAttribute("data-help-target", helpTarget);
        document.body.appendChild(element);
        const target = document.createElement("div");
        target.id = helpTarget;
        document.body.appendChild(target);
        const v = new TestHelpView(element);
        expect(v.button?.length).toBe(1);
        v.button?.trigger("click");
        expect($(target).text()).toBe("help text");
    });
});
