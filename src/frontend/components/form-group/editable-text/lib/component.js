import { Component } from "component";
import { asJSON, hideElement, showElement } from "util/common";

export default class EditableText extends Component {
    constructor(element) {
        super(element);
        console.log("EditableText")
        this.el = $(element);
        this.textbox = this.el.find('input');
        this.button = this.el.find('button');
        this.errorDisplay = this.el.find(".error-message");
        this.init();
    }

    init() {
        console.log("EditableText.init")
        this.currentText = this.textbox.val();
        hideElement(this.errorDisplay);
        this.textbox.on('keyup', (e)=>{
            console.log("EditableText.init.keyup")
            if(this.textbox.val() !== "" && this.currentText !== this.textbox.val()) {
                this.button.removeClass('disabled');
                this.button.attr('disabled', false);
            }else{
                this.button.addClass('disabled');
                this.button.attr('disabled', true);
            }
        });
        this.button.on('click', (e)=>{
            console.log("EditableText.init.click")
            this.saveChanges();
        });
    }

    saveChanges() {
        const requestData = { text: this.textbox.val(), csrf_token: $('body').data("csrf") };
        const data = JSON.stringify(requestData);
        const url = this.el.data('url');
        $.ajax({
            complete: (response) => {
                if (response && response.responseText && response.responseText) {
                    const jsonResponse = asJSON(response.responseText);
                    if (!jsonResponse.error) {
                        this.button.addClass('disabled');
                        this.currentText = jsonResponse.text;
                    } else {
                        this.errorDisplay.text(jsonResponse.text);
                        showElement(this.errorDisplay);
                    }
                }
            },
            contentType: 'application/json',
            data,
            url,
            error: (response) => {
                console.error(response);
            },
            method: 'POST',
        });
    }
}