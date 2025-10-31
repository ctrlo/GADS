import React from 'react';
import { FooterProps } from './types';
import { Dropdown } from 'react-bootstrap';

/**
 * Footer component for the dashboard
 * @param {FooterProps} props The properties for the footer component
 * @returns {React.JSX.Element} The rendered footer component
 */
export default function Footer({ addWidget, widgetTypes, currentDashboard, readOnly, noDownload }: FooterProps): React.JSX.Element {
    return (
        <div className='ld-footer-container'>
            {noDownload ||
                <Dropdown>
                    <Dropdown.Toggle className='btn-primary' variant="default" id="dropdown-download">
                        Download
                    </Dropdown.Toggle>

                    <Dropdown.Menu>
                        <Dropdown.Item href={currentDashboard.download_url}>As PDF</Dropdown.Item>
                    </Dropdown.Menu>
                </Dropdown>}

            {readOnly ||
                <Dropdown>
                    <Dropdown.Toggle className='btn-primary' variant="default" id="dropdown-add-widget">
                        Add Widget
                    </Dropdown.Toggle>

                    <Dropdown.Menu>
                        {widgetTypes.map(type => (
                            <Dropdown.Item key={type} onClick={(e) => { e.preventDefault(); addWidget(type); }}>{type}</Dropdown.Item>
                        ))}
                    </Dropdown.Menu>
                </Dropdown>}
        </div>
    );
}
