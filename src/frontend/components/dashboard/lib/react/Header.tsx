import React from "react";
import { HeaderProps } from "./types";
import MenuItem from "./Menu/MenuItem";

const Header = ({ hMargin, dashboards, currentDashboard, includeH1 }: HeaderProps) => {
  return (
    <div className="content-block__navigation" style={{marginLeft: hMargin, marginRight: hMargin}}>
      <div className="content-block__navigation-left">
        <div className="list list--horizontal list--no-borders">
          <ul id="menu_view" className="list__items" role="menu">
            {dashboards.map((dashboard, index) => (
              <li className="list__item" key={index}>
                <MenuItem dashboard={dashboard} currentDashboard={currentDashboard} includeH1={includeH1} />
              </li>
              ))}
          </ul>
        </div>
      </div>
    </div>
  );
};

export default Header;
