import "react-app-polyfill/ie9";
import "react-app-polyfill/stable";

import "core-js/es/array/is-array";
import "core-js/es/map";
import "core-js/es/set";
import "core-js/es/object/define-property";
import "core-js/es/object/keys";
import "core-js/es/object/set-prototype-of";

import "./polyfills/classlist";

import React from "react";
import ReactDOM from "react-dom";
import App from "./app";
import ApiClient from "./api";
import "./index.scss";

// grid configuration
const gridConfig = {
  cols: 12,
  margin: [10, 10],
  containerPadding: [10, 10],
  rowHeight: 80,
};

const root = document.getElementById("ld-app");

if (root) {
  root.className = "";
  const widgetsEls = Array.prototype.slice.call(root!.querySelectorAll("div"));
  const widgets = widgetsEls.map(el => ({
    html: el.innerHTML,
    config: JSON.parse(el.getAttribute("data-grid")),
  }));
  const api = new ApiClient(root.getAttribute("data-dashboard-endpoint") || "");

  ReactDOM.render(
    <App
      widgets={widgets}
      dashboardId={root.getAttribute("data-dashboard")}
      api={api}
      widgetTypes={JSON.parse(root.getAttribute("data-widget-types") || "[]")}
      gridConfig={gridConfig} />,
    root,
  );
}
