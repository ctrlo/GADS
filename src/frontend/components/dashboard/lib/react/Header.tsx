import React from "react";

const Header = ({ hMargin, dashboards, currentDashboard, loading }) => {
  const renderMenuItem = (dashboard) => {
    if (dashboard.name === currentDashboard.name) {
      return <span className="link link--primary link--active">{dashboard.name}</span>
    } else {
      return <a className="link link--primary" href={dashboard.url}><span>{dashboard.name}</span></a>
    }
  }
  return (
    <div className="content-block__navigation" style={{marginLeft: hMargin, marginRight: hMargin}}>
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
