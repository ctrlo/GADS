import React from "react";
import RGL, { WidthProvider } from "react-grid-layout";
import Widget from "../Widget/Widget";

const ReactGridLayout = WidthProvider(RGL);

export default function DashboardView({ readOnly, layout, onLayoutChange, gridConfig, widgets, onEditClick }) {
    return (<div className="content-block__main">
        { /* @ts-expect-error ReactGridLayout is apparently not a component */}
        <ReactGridLayout
            className={`content-block__main-content ${readOnly ? "" : "react-grid-layout--editable"}`}
            isDraggable={!readOnly}
            isResizable={!readOnly}
            draggableHandle=".ld-draggable-handle"
            useCSSTransforms={false}
            layout={layout}
            onLayoutChange={onLayoutChange}
            {...gridConfig}
        >
            {widgets.map(widget => (
                <div key={widget.config.i} className={`ld-widget-container ${readOnly || widget.config.static ? "" : "ld-widget-container--editable"}`}>
                    <Widget key={widget.config.i} html={widget.html} readOnly={readOnly || widget.config.static} onEditClick={onEditClick(widget.config.i)} />
                </div>
            ))}
        </ReactGridLayout>
    </div>);
}