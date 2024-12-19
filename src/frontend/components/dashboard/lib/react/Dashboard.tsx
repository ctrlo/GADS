'use client';

import React from "react";
import RGL, { WidthProvider } from "react-grid-layout";
import Modal from "react-modal";
import "react-grid-layout/css/styles.css";
import { DashboardState, WidgetData } from "./interfaces/interfaces";

const modalStyle: Modal.Styles = {
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
        padding: 0,
    },
    overlay: {
        zIndex: 1030,
        background: "rgba(0, 0, 0, .15)",
    },
};

const ReactGridLayout = WidthProvider(RGL);

export default function Dashboard(state: DashboardState) {
    // We can't pass refs around in the same way in functional components, so Widgets are no longer responsible for their own state
    return (<div className="content-block">
        {state.modalOpen && (
            <Modal
                isOpen={state.modalOpen}
                onRequestClose={state.closeModal}
                style={modalStyle}
                contentLabel="Edit Modal"
                shouldCloseOnOverlayClick={true}
            >
                <div className="modal-header">
                    <div className='modal-header__content'>
                        <h3 className="modal-title">Edit Widget</h3>
                    </div>
                    <button className="close" onClick={state.closeModal}>
                        <span aria-hidden="true" className="hidden">Close</span>
                    </button>
                </div>
                <div className="modal-body">
                    {state.editError && <p className="alert alert-danger">{state.editError}</p>}
                    {state.loadingEditHtml ? <span className="ld-modal__loading">Loading...</span> :
                        <div ref={state.formRef} dangerouslySetInnerHTML={{ __html: state.editHtml }} />}
                </div>
                <div className="modal-footer">
                    <div className="modal-footer__left">
                        <button className="btn btn-cancel" onClick={state.deleteActiveWidget}>Delete</button>
                    </div>
                    <div className="modal-footer__right">
                        <button className="btn btn-default" onClick={state.saveActiveWidget}>Close</button>
                    </div>
                </div>
            </Modal>
        )}
        <div className="content-block__main">
            <ReactGridLayout
                className={`content-block__main-content ${state.readOnly ? "" : "react-grid-layout--editable"}`}
                layout={state.widgets.map((element: WidgetData) => element.config)}
                onLayoutChange={state.layoutChange}
                isDraggable={!state.readOnly}
                isResizable={!state.readOnly}
                draggableHandle=".ld-draggable-handle"
                useCSSTransforms={false}
                {...state.config}
            >
                {state.widgets.map((widget: WidgetData) => (
                    <div key={widget.config.i} className={`ld-widget-container ${state.readOnly ? "" : "ld-widget-container--editable"}`}>
                        <div dangerouslySetInnerHTML={{ __html: widget.html }}></div>
                        {!state.readOnly && <a className="ld-edit-button" onClick={state.onEditClick(widget.config.i)}><span>Edit</span></a>}
                        <span className="ld-draggable-handle"><span>drag widget</span></span>
                    </div>
                ))}
            </ReactGridLayout>
        </div>
    </div>);
}