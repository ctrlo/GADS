import "../../../testing/globals.definitions";
import {layoutId, recordId} from "./common";

describe("Common button tests",()=>{
    it("should have a layoutId", ()=>{
        $('body').data('layout-identifier', 'layoutId');
        expect(layoutId()).toBe('layoutId');
    });

    it("should have a recordId", ()=>{
        expect(isNaN(parseInt(location.pathname.split('/').pop() ?? ""))).toBe(true);
        expect(recordId()).toBe(0);
    });
});