import React from "react";
import { HeaderProps } from "./types";
import MenuItem from "./Menu/MenuItem";
import { Nav } from "react-bootstrap";

const Header = ({ hMargin, dashboards, currentDashboard, includeH1 }: HeaderProps) => {
  return (
    <div style={{ marginLeft: hMargin, marginRight: hMargin, marginTop: "10px" }}>
      <Nav variant="pills">
        {dashboards.map((dashboard, index) => (
          <MenuItem dashboard={dashboard} currentDashboard={currentDashboard} includeH1={includeH1} key={index} />
        ))}
      </Nav>
    </div>
  );
};

export default Header;
