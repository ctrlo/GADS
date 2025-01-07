import { Component } from 'component'

import React from "react";
import ReactDOM from "react-dom/client";
import App from "./react/App";
import ApiClient from "./react/api";
import { ReactGridLayoutProps } from 'react-grid-layout';

class DashboardComponent extends Component {
  el: JQuery<HTMLElement>;
  gridConfig: ReactGridLayoutProps;

  constructor(element:HTMLElement)  {
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
    const widgets = widgetsEls.map((el: HTMLElement) => ({
      html: el.innerHTML,
      config: JSON.parse(el.getAttribute("data-grid")),
    }));
    const api = new ApiClient(this.element.getAttribute("data-dashboard-endpoint") || "");

    const root = ReactDOM.createRoot(this.element);

    root.render(
      <App
        widgets={widgets}
        dashboardId={this.element.getAttribute("data-dashboard-id")}
        currentDashboard={JSON.parse(this.element.getAttribute("data-current-dashboard") || "{}")}
        readOnly={this.element.getAttribute("data-dashboard-read-only") === "true"}
        hideMenu={this.element.getAttribute("data-dashboard-hide-menu") === "true"}
        includeH1={this.element.getAttribute("data-dashboard-include-h1") === "true"}
        noDownload={this.element.getAttribute("data-dashboard-no-download") === "true"}
        api={api}
        widgetTypes={JSON.parse(this.element.getAttribute("data-widget-types") || "[]")}
        dashboards={JSON.parse(this.element.getAttribute("data-dashboards") || "[]" )}
        gridConfig={this.gridConfig} />
    );
  }
}

export default DashboardComponent
