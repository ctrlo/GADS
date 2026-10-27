import React, { JSX } from "react";
import { Modal as Mdl, ModalBody, ModalHeader, ModalFooter } from "react-bootstrap";
import { AppModalProps } from "../types";

/**
 * The edit modal component
 * @param param0 Parameters for the edit modal
 * @returns The edit modal
 */
export default function EditModal({ editModalOpen, closeModal, editError, loadingEditHtml, editHtml, formRef, deleteActiveWidget, saveActiveWidget }: AppModalProps): JSX.Element {
    return (<Mdl show={editModalOpen} className="edit-widget-modal">
        <ModalHeader>
            <div className='modal-header__content'>
                <h3 className='modal-title'>Edit widget</h3>
            </div>
            <button className='btn close' onClick={closeModal}><span aria-hidden='true' className='hidden'>Close</span></button>
        </ModalHeader>
        <ModalBody>
            {editError
                && <p className="alert alert-danger">{editError}</p>}
            {loadingEditHtml
                ? <span className='ld-modal__loading'>Loading...</span> : <div ref={formRef} dangerouslySetInnerHTML={{ __html: editHtml ?? "" }} />}
        </ModalBody>
        <ModalFooter>
            <div className='modal-footer__left'>
                <button className="btn btn-cancel" onClick={deleteActiveWidget}>Delete</button>
            </div>
            <div className='modal-footer__right'>
                <button className="btn btn-primary" onClick={saveActiveWidget}>Save</button>
            </div>
        </ModalFooter>
    </Mdl>);
}
