import React, { createRef, useEffect } from "react";
import { initializeRegisteredComponents } from 'component'
import { WidgetViewProps } from "../types";

/**
 * Create a widget component
 * @param {WidgetViewProps} param0 The properties for the widget view
 * @returns {React.JSX.Element} The widget component
 */
export default function Widget({html, readOnly, onEditClick}: WidgetViewProps): React.JSX.Element {
  const ref = createRef<HTMLDivElement>();

  useEffect(()=>{
    if(!ref.current) return;
    initializeRegisteredComponents(ref.current);
  },[html]);

  return (
    <>
      <div className="ld-widget">
        <div ref={ref} dangerouslySetInnerHTML={{__html: html}}></div>
        {!readOnly && (<>
          <a data-testid="edit" className="ld-edit-button" onClick={onEditClick}><span>edit widget</span></a>
          <span data-testid="drag" className="ld-draggable-handle"><span>drag widget</span></span>
        </>)}
      </div>
    </>
  );
}
