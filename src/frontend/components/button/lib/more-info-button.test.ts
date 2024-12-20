import "testing/globals.definitions";
import createMoreInfoButton from "./more-info-button";
import { describe, it, expect, jest } from "@jest/globals";

describe("More info button", () => {
    it('should show a modal and attempt to set the HTML', () => {
        const load = jest.spyOn($.fn, "load").mockImplementation(() => { return $('body'); });
        const $button = $("<button class='btn' data-record-id='1' data-target='#modal'></button>");
        const $modal = $("<div id='modal'><div class='modal-title'></div><div class='modal-body text'></div></div>");
        $modal.appendTo(document.body);
        createMoreInfoButton($button);
        const event = $.Event("click");
        $button.trigger(event);
        expect($modal.find(".modal-body").text()).toBe("Loading...");
        expect(load).toHaveBeenCalledWith("/record_body/1");
    });
});
