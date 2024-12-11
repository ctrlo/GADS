// I wonder if this could be used as a "better" version of the UploadClient class with only minor modifications
import {Layout} from "react-grid-layout";
import {WidgetData} from "../interfaces/interfaces";

export default class ApiClient {
  private readonly baseUrl: string;
  private readonly headers: object;
  private readonly isDev: boolean;

  constructor(baseUrl = "") {
    this.baseUrl = baseUrl;
    this.headers = {};
    // @ts-expect-error "isDev is not valid"
    this.isDev = window.siteConfig && window.siteConfig.isDev
  }

  async _fetch(route: string, method: "POST" | "GET" | "PATCH" | "DELETE" | "PUT", body: any) {
    if (!route) throw new Error("Route is undefined");

    let csrfParam = "";
    if (method === "POST" || method === "PUT" || method === "PATCH" || method === "DELETE") {
      const body = document.querySelector("body");
      const csrfToken = body ? body.getAttribute("data-csrf") : null;
      if (csrfToken) {
        csrfParam = route.indexOf("?") > -1 ? `&csrf-token=${csrfToken}` : `?csrf-token=${csrfToken}`;
      }
    }

    const fullRoute = `${this.baseUrl}${route}${csrfParam}`;

    const opts: any = {
      method,
      headers: Object.assign(this.headers),
      credentials: 'same-origin', // Needed for older versions of Firefox, otherwise cookies not sent
    };
    if (body) {
      opts.body = JSON.stringify(body);
    }
    return fetch(fullRoute, opts);
  }

  private GET(route: string) {
    return this._fetch(route, "GET", null);
  }

  private POST(route: string, body: any) {
    return this._fetch(route, "POST", body);
  }

  private PUT(route: string, body: any) {
    return this._fetch(route, "PUT", body);
  }

  private DELETE(route: string) {
    return this._fetch(route, "DELETE", null);
  }

  saveLayout = (id: string|number, layout: Layout[]) => {
    if (!this.isDev) {
      const strippedLayout = layout.map(widget => ({...widget, moved: undefined}));
      return this.PUT(`/dashboard/${id}`, strippedLayout);
    }
  }

  createWidget = async (type: string) => {
    console.log("Creating widget of type", type);
    const response = this.isDev ? await this.GET(`/widget/create.json?type=${type}`) : await this.POST(`/widget?type=${type}`, null)
    return await response.json()
  }

  getWidgetHtml = async (id: string) => {
    const html = this.isDev ? await this.GET(`/widget/${id}/create`) : await this.GET(`/widget/${id}`)
    return html.text();
  }

  deleteWidget = (id: string) => !this.isDev && this.DELETE(`/widget/${id}`)

  getEditForm = async (id: string) => {
    const response = await this.GET(`/widget/${id}/edit`);
    return response.json();
  }

  saveWidget = async (url: string, params: any) => {
    const result = this.isDev ? await this.GET(`/widget/update.json`) : await this.PUT(`${url}`, params);
    return await result.json();
  }
}
