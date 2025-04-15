import React from "react";

/**
 * 
 * @param param0 Props for the Header component
 * @returns 
 */
const Header = ({ hMargin, dashboards, currentDashboard, loading, includeH1 }: {hMargin: number, dashboards: any[], currentDashboard: any, loading: boolean, includeH1: boolean}) => {
  const renderMenuItem = (dashboard: any) => {
    if (dashboard.name === currentDashboard.name) {
      if (includeH1) {
        return <h1><span className="link link--primary link--active">{dashboard.name}</span></h1>
      } else {
        return <span className="link link--primary link--active">{dashboard.name}</span>
      }
    } else {
      return <a className="link link--primary" href={dashboard.url}><span>{dashboard.name}</span></a>
    }
  }
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
