import { Component } from 'component'
import "react-app-polyfill/stable";

// import "core-js/es/array/is-array";
// import "core-js/es/map";
// import "core-js/es/set";
// import "core-js/es/object/define-property";
// import "core-js/es/object/keys";
// import "core-js/es/object/set-prototype-of";

import "./react/polyfills/classlist";

import React from "react";
import ReactDOM from "react-dom";
import App from "./react/app";
import ApiClient from "./react/api";

class DashboardComponent extends Component {
  constructor(element)  {
    super(element)
    this.el = $(this.element)

    this.gridConfig = {
      cols: 2,
      margin: [32, 32],
      containerPadding: [0, 10],
      rowHeight: 80,
    };

    this.initDashboard()
  }

  initDashboard() {
    this.element.className = "";
    const widgetsEls = Array.prototype.slice.call(document.querySelectorAll("#ld-app > div"));
    const widgets = widgetsEls.map(el => ({
      html: el.innerHTML,
      config: JSON.parse(el.getAttribute("data-grid")),
    }));
    const api = new ApiClient(this.element.getAttribute("data-dashboard-endpoint") || "");

    ReactDOM.render(
      <App
        widgets={widgets}
        dashboardId={this.element.getAttribute("data-dashboard-id")}
        currentDashboard={JSON.parse(this.element.getAttribute("data-current-dashboard") || "{}")}
        readOnly={this.element.getAttribute("data-dashboard-read-only") === "true"}
        hideMenu={this.element.getAttribute("data-dashboard-hide-menu") === "true"}
        noDownload={this.element.getAttribute("data-dashboard-no-download") === "true"}
        api={api}
        widgetTypes={JSON.parse(this.element.getAttribute("data-widget-types") || "[]")}
        dashboards={JSON.parse(this.element.getAttribute("data-dashboards") || "[]" )}
        gridConfig={this.gridConfig} />,
      this.element,
    );
  }
}

export default DashboardComponent
