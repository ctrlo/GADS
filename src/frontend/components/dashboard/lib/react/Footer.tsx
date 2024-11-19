import React from "react";

const Footer = ({ addWidget, widgetTypes, currentDashboard, readOnly, noDownload }) => {
  return (
    <div className='ld-footer-container'>
      {noDownload ? null : <div className="btn-group mb-3 mb-md-0 mr-md-4">
        <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
          Download <span className="caret"></span>
        </button>
        <div className="dropdown-menu dropdown__menu dropdown-menu--right scrollable-menu" role="menu">
          <ul id="menu_view" className="dropdown__list">
            <li className="dropdown__item">
              <a className="link link--plain" href={ currentDashboard.download_url }>As PDF</a>
            </li>
          </ul>
        </div>
      </div>}

      {readOnly ? null : <div className="btn-group">
        <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
          Add Widget
        </button>
        <div className="dropdown-menu dropdown__menu dropdown-menu--right scrollable-menu" role="menu">
          <ul id="menu_view" className="dropdown__list">
            {widgetTypes.map(type => (
              <li key={type} className="dropdown__item">
                <a className="link link--plain" href="#" onClick={(e) => {e.preventDefault(); addWidget(type)}}>{type}</a>
              </li>
            ))}
          </ul>
        </div>
      </div>}
    </div>
  );
};

export default Footer;
