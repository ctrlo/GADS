import React, { useEffect } from 'react';
import Modal from 'react-modal';

// A lot of state here - I think I will revisit this later
export default function EditModal({ editModalOpen, closeModal, editError, loadingEditHtml, editHtml, formRef, deleteActiveWidget, saveActiveWidget }) {
    const modalStyle: ReactModal.Styles = {
        content: {
            minWidth: "350px",
            maxWidth: "80vw",
            maxHeight: "90vh",
            top: "50%",
            left: "50%",
            right: "auto",
            bottom: "auto",
            marginRight: "-50%",
            transform: "translate(-50%, -50%)",
            msTransform: "translate(-50%, -50%)",
            padding: 0
        },
        overlay: {
            zIndex: 1030,
            background: "rgba(0, 0, 0, .15)"
        }
    };

    useEffect(() => {
        Modal.setAppElement("#ld-app");
    }, []);

    /* @ts-expect-error Modal is apparently not a component */
    return (<Modal
        isOpen={editModalOpen}
        onRequestClose={closeModal}
        style={modalStyle}
        shouldCloseOnOverlayClick={true}
        contentLabel="Edit Modal"
    >
        <div className='modal-header'>
            <div className='modal-header__content'>
                <h3 className='modal-title'>Edit widget</h3>
            </div>
            <button className='close' onClick={closeModal}><span aria-hidden='true' className='hidden'>Close</span></button>
        </div>
        <div className="modal-body">
            {editError
                && <p className="alert alert-danger">{editError}</p>}
            {loadingEditHtml
                ? <span className='ld-modal__loading'>Loading...</span> : <div ref={formRef} dangerouslySetInnerHTML={{ __html: editHtml }} />}
        </div>
        <div className='modal-footer'>
            <div className='modal-footer__left'>
                <button className="btn btn-cancel" onClick={deleteActiveWidget}>Delete</button>
            </div>
            <div className='modal-footer__right'>
                <button className="btn btn-default" onClick={saveActiveWidget}>Save</button>
            </div>
        </div>
    </Modal>)
}