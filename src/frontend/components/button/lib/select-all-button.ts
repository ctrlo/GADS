export default function createSelectAllButton(el: HTMLElement | JQuery<HTMLElement>) {
    const $el = $(el);
    if(!$el.data('action')) throw new Error('Invalid data-action value');
    $el.on('click', () => {
        const $checkboxes = $el.closest('.togglelist').find('input[type="checkbox"]');
        $checkboxes.each((_index, element) => {
            const $element = $(element);
            if ($el.data('action') == 'check') {
                $element.attr('checked', 'checked');
                $element.prop('checked', true);
            } else if ($el.data('action') == 'uncheck') {
                $element.removeAttr('checked');
                $element.prop('checked', false);
            }
            $element.trigger('change');
        });
    });
}
