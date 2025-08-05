import React from 'react';
import { MenuProps } from '../types';
import { Nav } from 'react-bootstrap';

/**
 * Render a menu item for the dashboard.
 * @param {MenuProps} param0 Menu properties
 * @returns {React.JSX.Element} Rendered menu item
 */
export default function MenuItem({ dashboard, currentDashboard, includeH1 }: MenuProps): React.JSX.Element {
    if (dashboard.name === currentDashboard.name) {
        if (includeH1) {
            return <Nav.Item>
                <Nav.Link active href={dashboard.url}><h1><span>{dashboard.name}</span></h1></Nav.Link>
            </Nav.Item>;
        } else {
            return <Nav.Item>
                <Nav.Link active href={dashboard.url}><span>{dashboard.name}</span></Nav.Link>
            </Nav.Item>;
        }
    } else {
        return <Nav.Item>
            <Nav.Link href={dashboard.url}><span>{dashboard.name}</span></Nav.Link>
        </Nav.Item>;
    }
}
