import { validateRequiredFields } from 'validation';
import '@lol768/jquery-querybuilder-no-eval';

/**
 * Button component for saving views for an instance.
 * @param {JQuery<HTMLElement>} el The jQuery element that represents the Save View button.
 */
export default function createSaveViewButtonComponent(el: JQuery<HTMLElement>) {
    const $form = el.closest('form');
    const $global = $form.find('#global');
    const $dropdown = $form.find('.select.dropdown');
    $global.on('change', (ev) => {
        const $input = $form.find('input[type=hidden][name=group_id]');
        if ((ev.target as HTMLInputElement)?.checked) {
            $input.attr('required', 'required');
            if ($dropdown && $dropdown.attr && $dropdown.attr('placeholder') && $dropdown.attr('placeholder').match(/All [Uu]sers/)) $dropdown.addClass('select--required');
        } else {
            $input.removeAttr('required');
            if ($dropdown && $dropdown.attr && $dropdown.attr('placeholder') && $dropdown.attr('placeholder').match(/All [Uu]sers/)) $dropdown.removeClass('select--required');
        }
    });
    el.on('click', (ev) => {
        const $form = $(ev.target).closest('form');
        if (!validateRequiredFields($form)) ev.preventDefault();
        const select = $form.find('input[type=hidden][name=group_id]');
        if (select.val() === 'allusers') {
            select.val('');
            select.removeAttr('required');
        }
        $('.filter').each((_i, el) => {
            //Bit of typecasting here, purely because the queryBuilder plugin doesn't have types
            if (!(<any>$(el)).queryBuilder('validate')) ev.preventDefault();
            const res = (<any>$(el)).queryBuilder('getRules');
            $(el).next('#filter')
                .val(JSON.stringify(res, null, 2));
        });
    });
}
