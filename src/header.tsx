import React, { useState } from "react";
import "./header.scss";

const Header = ({ widgetTypes, addWidget, hMargin }) => {
  const [type, setType] = useState(widgetTypes[0]);
  return (
    <div className='ld-header-container' style={{marginLeft: hMargin, marginRight: hMargin}}>
      <select value={type} onChange={e => setType(e.target.value)}>
        {widgetTypes.map(t => (
          <option key={t} value={t}>{t}</option>
        ))}
      </select>
      <button onClick={() => addWidget(type)}>Add Widget</button>
    </div>
  );
};

export default Header;
