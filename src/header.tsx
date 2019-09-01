import React from "react";
import "./header.scss";

const Header = ({ widgetTypes, addWidget, hMargin, dashboards, dashboardName }) => {
  return (
    <div className='ld-header-container' style={{marginLeft: hMargin, marginRight: hMargin}}>
      <div className="btn-group">
        <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
          Add Widget <span className="caret"></span>
        </button>
        <ul id="menu_view" className="dropdown-menu dropdown-menu-right scrollable-menu" role="menu">
			    <li>
            {widgetTypes.map(type => (
              <a href="#" key={type} onClick={(e) => {e.preventDefault(); addWidget(type)}}>{type}</a>
            ))}
          </li>
        </ul>
      </div>
        &nbsp;
      <div className="btn-group">
        <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
          { dashboardName } <span className="caret"></span>
        </button>
        <ul id="menu_view" className="dropdown-menu dropdown-menu-right scrollable-menu" role="menu">
			    <li>
            {dashboards.map(dashboard => (
              <a href={dashboard.url}>{dashboard.name}</a>
            ))}
          </li>
        </ul>
      </div>
    </div>
  );
};

export default Header;
