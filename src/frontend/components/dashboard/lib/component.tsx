// We're using the 'client' side of React, not server, nor native.
'use client'

import { Component } from 'component'
import "react-app-polyfill/stable";

import "core-js/es/array/is-array";
import "core-js/es/map";
import "core-js/es/set";
import "core-js/es/object/define-property";
import "core-js/es/object/keys";
import "core-js/es/object/set-prototype-of";

import "./react/polyfills/classlist";

import React from "react";
import {createRoot} from "react-dom/client";
import App from "./react/App";
import ApiClient from "./react/api";
import { fromJson } from 'util/common';
import {DashboardDefinition} from "./react/interfaces/interfaces";

class DashboardComponent extends Component {
  constructor(element: HTMLElement)  {
    super(element)

    this.initDashboard()
  }

  initDashboard() {
    this.element.className = "";
    const widgetsEls = Array.prototype.slice.call(document.querySelectorAll("#ld-app > div"));
    const widgets = widgetsEls.map((el:HTMLElement) => ({
      html: el.innerHTML,
      config: fromJson(el.getAttribute("data-grid")),
    }));
    const api = new ApiClient(this.element.getAttribute("data-dashboard-endpoint") || "");

    createRoot(this.element).render(
      <App
        api={api}
        currentDashboard={fromJson(this.element.getAttribute("data-dashboard"))}
        dashboards={fromJson(this.element.getAttribute("data-dashboards")) as DashboardDefinition[]}
        hideMenu={this.element.getAttribute("data-hide-menu") === "true"}
        noDownload={this.element.getAttribute("data-no-download") === "true"}
        readOnly={this.element.getAttribute("data-read-only") === "true"}
        widgetTypes={fromJson(this.element.getAttribute("data-widget-types")) as string[]}
        widgets={widgets}
        key={this.element.getAttribute("data-dashboard")}
        dashboardId={parseInt(this.element.getAttribute("data-dashboard-id"))} />
    );
  }
}

export default DashboardComponent
