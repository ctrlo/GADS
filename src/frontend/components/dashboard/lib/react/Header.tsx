import React from 'react';

/**
 * Create a Header component that displays a navigation header for dashboards.
 * @param {object} param0 The properties for the Header component, including horizontal margin, list of dashboards, current dashboard, loading state, and a flag to include an H1 element.
 * @param {number} param0.hMargin The horizontal margin to apply to the header.
 * @param {Array} param0.dashboards The list of dashboards to display in the header.
 * @param {{name: string}} param0.currentDashboard The currently active dashboard.
 * @param {boolean} param0.loading A flag indicating whether the header is in a loading state.
 * @param {boolean} param0.includeH1 A flag indicating whether to include an
 * @returns {JSX.Element} The rendered Header component.
 */
const Header = ({ hMargin, dashboards, currentDashboard, loading, includeH1 }: { hMargin: number; dashboards: Array<any>; currentDashboard: {name: string}; loading: boolean; includeH1: boolean; }): JSX.Element => {
    const renderMenuItem = (dashboard) => {
        if (dashboard.name === currentDashboard.name) {
            if (includeH1) {
                return <h1><span className="link link--primary link--active">{dashboard.name}</span></h1>;
            } else {
                return <span className="link link--primary link--active">{dashboard.name}</span>;
            }
        } else {
            return <a className="link link--primary" href={dashboard.url}><span>{dashboard.name}</span></a>;
        }
    };
    return (
        <div className="content-block__navigation" style={{ marginLeft: hMargin, marginRight: hMargin }}>
            <div className="content-block__navigation-left">
                {loading ? <p className="spinner"><i className="fa fa-spinner fa-spin"></i></p> : null}
                <div className="list list--horizontal list--no-borders">
                    <ul id="menu_view" className="list__items" role="menu">
                        {dashboards.map((dashboard, index) => (
                            <li className="list__item" key={index}>
                                {renderMenuItem(dashboard)}
                            </li>
                        ))}
                    </ul>
                </div>
            </div>
        </div>
    );
};

export default Header;
