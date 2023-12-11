import { modal } from '../../../lib/modal'
import ModalComponent from "../../../lib/component";

class ReportSettingComponent extends ModalComponent {
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.input = this.el.find('input[name="setting_value"]');
        this.submit = this.el.find('button[type="submit"]');
        this.initReportSettingModal();
    }

    initReportSettingModal() {
        this.el.on('show.bs.modal', (ev) => {
            this.toggleContent(ev);
        });
    }

    toggleContent(ev) {
        if (ev.relatedTarget.classList.contains('btn-edit')) {
            const value = $(ev.relatedTarget).data("current-value");
            const title = $(ev.relatedTarget).data("title");
            this.input.val(value);
            this.submit.val(title);
        }
    }
}

export default ReportSettingComponent;