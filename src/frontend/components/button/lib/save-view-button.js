import {Component} from "component";
import {validateRequiredFields} from "validation";

export default class SaveViewButtonComponent extends Component {
    constructor(element) {
        super(element);
        this.el = $(element);
        this.initSaveView();
    }

    initSaveView() {
        const $form = this.el.closest('form');
        const $global = $form.find('#global');
        const $dropdown = $form.find(".select.dropdown")
        $global.on('change', (ev) => {
            const $input = $form.find('input[type=hidden][name=group_id]');
            if (ev.target.checked) {
                $input.attr('required', 'required');
                if($dropdown.attr("placeholder").match(/All [Uu]sers/)) $dropdown.addClass('select--required');
            } else {
                $input.removeAttr('required');
                if($dropdown.attr("placeholder").match(/All [Uu]sers/)) $dropdown.removeClass('select--required');
            }
        });
        this.el.on('click', (ev) => {
            this.saveView(ev);
        });
    }

    saveView(ev) {
        const $form = $(ev.target).closest('form');
        if(!validateRequiredFields($form)) ev.preventDefault();
        const select = $form.find('input[type=hidden][name=group_id]');
        if(select.val() === 'allusers') {
            select.val('');
            select.removeAttr('required');
        }
        $(".filter").each((i, el) => {
            if (!$(el).queryBuilder('validate')) ev.preventDefault();
            const res = $(el).queryBuilder('getRules')
            $(el).next('#filter').val(JSON.stringify(res, null, 2))
        })
    }
}