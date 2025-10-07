import React from 'react';
import RGL, { WidthProvider } from 'react-grid-layout';
import Widget from '../Widget/Widget';
import { DashboardViewProps } from '../types';

const ReactGridLayout = WidthProvider(RGL);

/**
 * Render the Dashboard view.
 * @param {DashboardViewProps} param0 Dashboard properties
 * @returns {React.JSX.Element} Rendered Dashboard view
 */
export default function DashboardView({ readOnly, layout, onLayoutChange, gridConfig, widgets, onEditClick }: DashboardViewProps): React.JSX.Element {
    return (<div className="content-block__main">
        <ReactGridLayout
            className={`content-block__main-content ${readOnly ? '' : 'react-grid-layout--editable'}`}
            isDraggable={!readOnly}
            isResizable={!readOnly}
            draggableHandle=".ld-draggable-handle"
            useCSSTransforms={false}
            layout={layout}
            onLayoutChange={onLayoutChange}
            {...gridConfig}
        >
            {widgets.map(widget => (
                <div key={widget.config.i} className={`ld-widget-container ${readOnly || widget.config.static ? '' : 'ld-widget-container--editable'}`}>
                    <Widget key={widget.config.i} html={widget.html} readOnly={readOnly || widget.config.static} onEditClick={onEditClick(widget.config.i)} />
                </div>
            ))}
        </ReactGridLayout>
    </div>);
}
