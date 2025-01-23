import { Layout } from "react-grid-layout";

type RequestMethod = "GET" | "POST" | "PUT" | "PATCH" | "DELETE";

export default class ApiClient {
  private baseUrl: string;
  private headers: { [key: string]: string };
  private isDev: boolean;

  constructor(baseUrl = "") {
    this.baseUrl = baseUrl;
    this.headers = {};
    // @ts-expect-error "isDev is not valid"
    this.isDev = window.siteConfig && window.siteConfig.isDev;
  }

  async _fetch<T extends object = object>(route: string, method: RequestMethod, body?: T) {
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

  GET(route: string) { return this._fetch(route, "GET"); }

  POST<T extends object = object>(route: string, body: T) { return this._fetch(route, "POST", body); }

  PUT<T extends object = object>(route: string, body: T) { return this._fetch(route, "PUT", body); }

  PATCH<T extends object = object>(route: string, body: T) { return this._fetch(route, "PATCH", body); }

  DELETE(route: string) { return this._fetch(route, "DELETE"); }

  saveLayout = (id: string, layout: Layout[]) => {
    if (!this.isDev) {
      const strippedLayout = layout.map(widget => ({ ...widget, moved: undefined }));
      return this.PUT(`/dashboard/${id}`, strippedLayout);
    }
  }

  createWidget = async (type: string) => {
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
