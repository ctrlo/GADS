import React from 'react';

/**
 * Create a Footer component that displays options for downloading the dashboard and adding widgets.
 * @param param0 The properties for the Footer component, including a function to add a widget, a list of widget types, the current dashboard, a read-only flag, and a no-download flag.
 * @param {function} param0.addWidget Function to call when adding a widget.
 * @param {Array} param0.widgetTypes The list of widget types available for addition.
 * @param {object} param0.currentDashboard The currently active dashboard.
 * @param {boolean} param0.readOnly A flag indicating whether the dashboard is in read-only mode.
 * @param {boolean} param0.noDownload A flag indicating whether the download option
 * @returns {JSX.Element} The rendered Footer component.
 */
const Footer = ({ addWidget, widgetTypes, currentDashboard, readOnly, noDownload }): JSX.Element => {
    return (
        <div className='ld-footer-container'>
            {noDownload ? null : <div className="btn-group mb-3 mb-md-0 mr-md-4">
                <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
                    Download <span className="caret"></span>
                </button>
                <div className="dropdown-menu dropdown__menu dropdown-menu-right scrollable-menu" role="menu">
                    <ul id="menu_view" className="dropdown__list">
                        <li className="dropdown__item">
                            <a className="link link--plain" href={currentDashboard.download_url}>As PDF</a>
                        </li>
                    </ul>
                </div>
            </div>}

            {readOnly ? null : <div className="btn-group">
                <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false" aria-controls="menu_view">
                    Add Widget
                </button>
                <div className="dropdown-menu dropdown__menu dropdown-menu-right scrollable-menu" role="menu">
                    <ul id="menu_view" className="dropdown__list">
                        {widgetTypes.map(type => (
                            <li key={type} className="dropdown__item">
                                <a className="link link--plain" href="#" onClick={(e) => { e.preventDefault(); addWidget(type); }}>{type}</a>
                            </li>
                        ))}
                    </ul>
                </div>
            </div>}
        </div>
    );
};

export default Footer;
