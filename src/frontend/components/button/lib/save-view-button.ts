import { validateRequiredFields } from "validation";
import "@lol768/jquery-querybuilder-no-eval";
import { BaseButton } from "./base-button";

class SaveViewButton extends BaseButton {
    type = 'btn-js-save-view';
    $form: JQuery<HTMLElement>;
    $global: JQuery<HTMLElement>;
    $dropdown: JQuery<HTMLElement>;
    
    click(ev: JQuery.ClickEvent): void {
        const $form = $(ev.target).closest('form');
        if (!validateRequiredFields($form)) ev.preventDefault();
        const select = $form.find('input[type=hidden][name=group_id]');
        if (select.val() === 'allusers') {
            select.val('');
            select.removeAttr('required');
        }
        $(".filter").each((_i, el) => {
            //Bit of typecasting here, purely because the queryBuilder plugin doesn't have types
            if (!(<any>$(el)).queryBuilder('validate')) ev.preventDefault();
            const res = (<any>$(el)).queryBuilder('getRules');
            $(el).next('#filter').val(JSON.stringify(res, null, 2));
        });
    }

    init(): void {
        this.$form = this.element.closest('form');
        this.$global = this.$form.find('#global');
        this.$dropdown = this.$form.find(".select.dropdown");
        this.$global.on('change', (ev) => {
            const $input = this.$form.find('input[type=hidden][name=group_id]');
            if ((ev.target as HTMLInputElement)?.checked) {
                $input.attr('required', 'required');
                if (this.$dropdown && this.$dropdown.attr && this.$dropdown.attr("placeholder") && this.$dropdown.attr("placeholder").match(/All [Uu]sers/)) this.$dropdown.addClass('select--required');
            } else {
                $input.removeAttr('required');
                if (this.$dropdown && this.$dropdown.attr && this.$dropdown.attr("placeholder") && this.$dropdown.attr("placeholder").match(/All [Uu]sers/)) this.$dropdown.removeClass('select--required');
            }
        });
    }

}

export default function createSaveViewButtonComponent(el: HTMLElement | JQuery<HTMLElement>) {
    return new SaveViewButton($(el));
}