import DataTableComponent from "./component";

global.$ = require('jquery');

describe('DataTable Component', () => {
    beforeEach(() => {
        $.ajax = jest.fn((config) => {
            config.success([
                { name: "test", values: [1, 2, 3] },
            ]);
        });
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('gets proper uri', () => {
        const expected = "/api/test/fields";
        const component = new DataTableComponent(document.body);
        const actual = component.getDataUri("/test/view");
        expect(actual).toEqual(expected);
    });

    it('gets proper data', () => {
        const component = new DataTableComponent(document.body);
        component.initData();
        expect($.ajax).toHaveBeenCalledWith({
            url: "/api//fields",
            success: expect.any(Function),
            error: expect.any(Function)
        });
        expect(component.data).toEqual([
            { name: "test", values: [1, 2, 3] },
        ]);
    });

    it('finds proper data', () => {
        const component = new DataTableComponent(document.body);
        component.initData();
        expect($.ajax).toHaveBeenCalledWith({
            url: "/api//fields",
            success: expect.any(Function),
            error: expect.any(Function)
        });
        expect(component.data).toEqual([
            { name: "test", values: [1, 2, 3] },
        ]);
        const actual = component.getHiddenValues("test");
        expect(actual).toEqual([1, 2, 3]);     
    });
});