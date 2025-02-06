import React from "react";
import { FooterProps } from "./types";
import { Dropdown } from "react-bootstrap";

const Footer = ({ addWidget, widgetTypes, currentDashboard, readOnly, noDownload }: FooterProps) => {
  return (
    <div className='ld-footer-container'>
      {noDownload ||
        <Dropdown>
          <Dropdown.Toggle variant="default" id="dropdown-basic">
            Download
          </Dropdown.Toggle>

          <Dropdown.Menu>
            <Dropdown.Item href={currentDashboard.download_url}>As PDF</Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>}
      
      {readOnly || 
        <Dropdown>
          <Dropdown.Toggle variant="default" id="dropdown-basic">
            Add Widget
          </Dropdown.Toggle>

          <Dropdown.Menu>
            {widgetTypes.map(type => (
              <Dropdown.Item key={type} onClick={(e) => {e.preventDefault(); addWidget(type)}}>{type}</Dropdown.Item>
            ))}
          </Dropdown.Menu>
        </Dropdown>}
    </div>
  );
};

export default Footer;
