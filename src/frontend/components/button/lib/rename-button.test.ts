import "testing/globals.definitions";
import "./rename-button.ts";
import {expect, it, describe, afterEach, jest} from "@jest/globals";
import { RenameEvent } from "./rename-button.ts";

describe("rename-button", () => {
    const fileDom = `
<div class="row">
    <div class="col-auto align-content-center">
        <input type="checkbox" id="file-1" name="field" value="1" aria-label="old.png" data-filename="old.png" checked="">
        <label for="file-1">Include File. Current file name:</label>
        <a id="current-1" class="link link--plain" href="/file/1">old.png</a>
        <button data-field-id="1" class="rename btn btn-plain btn-small btn-sm py-0" title="Rename file" type="button"></button>
    </div>
</div>
    `;

    it("Throws an error if the ID is undefined", ()=>{
        const $dom = $(fileDom);
        const button = $dom.find(".rename");
        button.data("fieldId", null);
        expect(()=>{button.renameButton()}).toThrowError("File ID is null or empty");
    });

    it("Throws an error if the ID is not a number", ()=>{
        const $dom = $(fileDom);
        const button = $dom.find(".rename");
        button.data("fieldId", "a");
        expect(()=>{button.renameButton()}).toThrowError("Invalid file id!");
    });

    it("Creates the elements for the rename", ()=>{
        const dom = $(fileDom);
        const button = dom.find(".rename");
        let $input = dom.find("#file-rename-1");
        let $confirm = dom.find("#rename-confirm-1");
        let $cancel = dom.find("#rename-cancel-1");
        expect($input.length).toBe(0);
        expect($confirm.length).toBe(0);
        expect($cancel.length).toBe(0);
        button.renameButton();
        $input = dom.find("#file-rename-1");
        $confirm = dom.find("#rename-confirm-1");
        $cancel = dom.find("#rename-cancel-1");
        expect($input.length).toBe(1);
        expect($confirm.length).toBe(1);
        expect($cancel.length).toBe(1);
    });

    it("Performs the rename click", ()=>{
        expect.assertions(2); // We need to be certain the event is triggered
        const dom = $(fileDom);
        const $body = $("body");
        $body.append(dom);
        const button = $body.find(".rename");
        button.renameButton();
        button.on("rename", (ev: RenameEvent)=>{
            expect(ev.oldName).toBe("old.png");
            expect(ev.newName).toBe("new.png");
        });
        button.trigger("click");
        const $input = $body.find("#file-rename-1");
        const $confirm = $body.find("#rename-confirm-1");
        $input.val("new");
        $input.trigger("blur");
        $confirm.trigger("click");
        $body.empty();
    });
});