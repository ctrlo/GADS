import React from "react";
import "./header.scss";

const Header = ({ widgetTypes, addWidget, hMargin, dashboards, currentDashboard, readOnly, loading }) => {
  return (
    <div className='ld-header-container' style={{marginLeft: hMargin, marginRight: hMargin}}>
      {loading ? <p className="spinner"><i className="fa fa-spinner fa-spin"></i></p> : null}
      <div className="btn-group">
        <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
          Download <span className="caret"></span>
        </button>
        <ul id="menu_view" className="dropdown-menu dropdown-menu-right scrollable-menu" role="menu">
          <li><a href={ currentDashboard.download_url }>As PDF</a>
          </li>
        </ul>
      </div>
        &nbsp;
      {readOnly ? null : <div className="btn-group">
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
      </div>}
        &nbsp;
      <div className="btn-group">
        <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
          { currentDashboard.name } <span className="caret"></span>
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
