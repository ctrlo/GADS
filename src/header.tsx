import React, { useState } from "react";
import "./header.scss";

const Header = ({ widgetTypes, addWidget, hMargin }) => {
  const [currentType, setType] = useState(widgetTypes[0]);
  return (
    <div className='ld-header-container' style={{marginLeft: hMargin, marginRight: hMargin}}>
      <select className="form-control" style={{width: 150}} value={currentType} onChange={event => setType(event.target.value)}>
        {widgetTypes.map(type => (
          <option key={type} value={type}>{type}</option>
        ))}
      </select>
      <button className="btn btn-primary" onClick={() => addWidget(currentType)}>Add Widget</button>
    </div>
  );
};

export default Header;
