import React, { createRef, useEffect } from "react";
import { initializeRegisteredComponents } from 'component'

export default function Widget({html, readOnly, onEditClick}) {
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
          <a className="ld-edit-button" onClick={onEditClick}><span>edit widget</span></a>
          <span className="ld-draggable-handle"><span>drag widget</span></span>
        </>)}
      </div>
    </>
  );
}
