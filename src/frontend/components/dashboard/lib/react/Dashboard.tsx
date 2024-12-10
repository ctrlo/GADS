'use client';

import React, { useRef } from "react";
import RGL, { WidthProvider } from "react-grid-layout";
import Modal from "react-modal";
import "react-grid-layout/css/styles.css";
import { DashboardState, Widget } from "./interfaces/interfaces";

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
    const formRef = useRef<HTMLDivElement>(null);

    console.log("Dashboard state", state);

    return (<div className="content-main">
        {state.modalOpen && (
            <Modal
                isOpen={state.modalOpen}
                onRequestClose={state.closeModal}
                style={modalStyle}
                contentLabel="Edit Modal"
                shouldCloseOnOverlayClick={true}
                ariaHideApp={false}
            >
                <div className="modal-header">
                    <h3>Edit Widget</h3>
                    <button onClick={state.closeModal}>Close</button>
                </div>
                <div className="modal-body">
                    {state.editError && <p className="alert alert-danger">{state.editError}</p>}
                    {state.loadingEditHtml ? <span>Loading...</span> :
                        <div ref={formRef} dangerouslySetInnerHTML={{ __html: state.editHtml }} />}
                </div>
                <div className="modal-footer">
                    <button onClick={state.deleteActiveWidget}>Delete</button>
                    <button onClick={state.saveActiveWidget}>Close</button>
                </div>
            </Modal>
        )}
        <ReactGridLayout
            className={`content-block__main-content ${state.readOnly ? "" : "react-grid-layout--editable"}`}
            layout={state.widgets.map((element: Widget) => element.config)}
            onLayoutChange={state.layoutChange}
            {...state.config}
        >
            {state.widgets.map((element: Widget) => 
                <div key={element.config.i} className="ld-main">
                    <div dangerouslySetInnerHTML={{ __html: element.html }}></div>
                </div>)}
        </ReactGridLayout>
    </div>);
}