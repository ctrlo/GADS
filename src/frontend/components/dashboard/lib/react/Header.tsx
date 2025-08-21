import React from 'react';
import { HeaderProps } from './types';
import MenuItem from './Menu/MenuItem';
import { Nav } from 'react-bootstrap';

/**
 * Render the header for the dashboard
 * @param {HeaderProps} param0 Header component properties
 * @returns {React.JSX.Element} The rendered header component
 */
export default function Header ({ hMargin, dashboards, currentDashboard, includeH1 }: HeaderProps): React.JSX.Element {
    return (
        <div style={{ marginLeft: hMargin, marginRight: hMargin, marginTop: '10px' }}>
            <Nav variant="pills" className="border-bottom pb-3 mb-3">
                {dashboards.map((dashboard, index) => (
                    <MenuItem dashboard={dashboard} currentDashboard={currentDashboard} includeH1={includeH1} key={index} />
                ))}
            </Nav>
        </div>
    );
}
