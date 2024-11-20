import "../../../testing/globals.definitions";
import {layoutId, recordId, table_key} from "./common";

describe("Common button tests",()=>{
    it("should populate table_key",()=>{
        expect(table_key()).toBe("linkspace-record-change-undefined-0"); // Undefiined because $('body').data('layout-identifier') is not defined
    });

    it("should have a layoutId", ()=>{
        $('body').data('layout-identifier', 'layoutId');
        expect(layoutId()).toBe('layoutId');
    });

    it("should have a recordId", ()=>{
        expect(isNaN(parseInt(location.pathname.split('/').pop() ?? ""))).toBe(true);
        expect(recordId()).toBe(0);
    });

    it("should populate table_key fully",()=>{
        $('body').data('layout-identifier', 'layoutId');
        expect(table_key()).toBe("linkspace-record-change-layoutId-0");
    });
});