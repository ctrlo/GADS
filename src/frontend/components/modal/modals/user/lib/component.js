import { modal } from '../../../lib/modal';
import ModalComponent from '../../../lib/component';

/**
 * Modal component for user management
 * This component handles the account approval processes.
 */
class UserModalComponent extends ModalComponent {
    /**
     * Constructor for UserModalComponent
     * @param {HTMLElement} element - The modal element
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.emailField = this.el.find('input[name="email"]');
        this.emailText = this.el.find('.js-email');

        this.initUserModal();
    }

    /**
     * Initialize the user modal
     */
    initUserModal() {
        this.el.on('show.bs.modal', (ev) => {
            this.toggleContent(ev);
            modal.validate();
            this.updateEmail();
            this.emailField.on('keyup',() => { this.updateEmail(); });
        });
    }

    /**
     * Toggle the right content (add user or approve account)
     * @param {Event} ev - The event triggered when the modal is shown
     */
    toggleContent(ev) {
        this.target = $(ev.relatedTarget);
        if (this.target.hasClass('btn-add')) {
            modal.clear();
            this.el.find('.js-approve-account').hide();
            this.el.find('.js-add-user').show();
            this.el.find('.btn-js-reject-request').hide();
            this.el.find('.btn-js-save .btn__title').html('Create account');
            this.el.find('input[name="approve-account"]').val('false');
        } else {
            this.el.find('.js-add-user').hide();
            this.el.find('.js-approve-account').show();
            this.el.find('.btn-js-reject-request').show()
                .on('click', () => {
                    this.activateFrame(4);
                });
            this.el.find('.btn-js-save .btn__title').html('Approve account');
            this.el.find('input[name="approve-account"]').val('true');
        }
    }

    /**
     * Update the text container for the email address
     */
    updateEmail() {
        this.emailText.html(this.emailField.val());
    }

    /**
     * Get all data from all fields in the modal
     * @returns {object} An object containing the data from the modal fields
     */
    getData() {
        const data = {
            view_limits: [],
            permissions: [],
            groups: []
        };

        this.el.find('input, textarea').each((i, field) => {
            if (($(field).prop('type') === 'radio' || $(field).prop('type') === 'checkbox')) {
                if ($(field).prop('checked')) {
                    const fieldValue = isNaN($(field).val()) ? $(field).val() : parseInt($(field).val());
                    if (Array.isArray(data[$(field).attr('name')])) {
                        data[$(field).attr('name')].push(fieldValue);
                    } else {
                        data[$(field).attr('name')] = fieldValue;
                    }
                }
            } else if ($(field).val() || $(field).value) {
                const fieldValue = $(field).val() || $(field).value;
                const fieldParsedValue = isNaN(fieldValue) ? this.parseValue(fieldValue) : parseInt(fieldValue);
                if (Array.isArray(data[$(field).attr('name')])) {
                    data[$(field).attr('name')].push(fieldParsedValue);
                } else {
                    data[$(field).attr('name')] = fieldParsedValue;
                }
            }
        });

        return data;
    }

    /**
     * Parse a value from the modal fields
     * @param {string} val The value to parse
     * @returns {boolean|string} The parsed value, converting 'true'/'false' strings to boolean or returning the original value if not a boolean string
     */
    parseValue(val) {
        return val === 'true' ? true : val === 'false' ? false : val;
    }

    /**
     * Handle save
     */
    handleSave() {
        modal.upload(this.getData());
    }

    /**
     * Handle close
     */
    handleClose() {
        super.handleClose();
        this.emailText.html('USER');
    }

    /**
     * Handle back navigation
     */
    handleBack() {
        super.handleBack();
        if (this.target.hasClass('btn-add')) return;
        this.el.find('.btn-js-reject-request').off()
            .on('click', () => {
                this.activateFrame(4);
            });
    }

    /**
     * Handle next navigation
     */
    handleNext() {
        super.handleNext();
        if (this.target.hasClass('btn-add')) return;
        this.el.find('.btn-js-reject-request').off()
            .on('click', () => {
                this.activateFrame(4);
            });
    }
}

export default UserModalComponent;
