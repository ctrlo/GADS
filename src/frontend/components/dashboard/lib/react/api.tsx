export default class ApiClient {
  private baseUrl;
  private headers;
  private isDev;

  constructor(baseUrl = "") {
    this.baseUrl = baseUrl;
    this.headers = {};
    this.isDev = window.siteConfig && window.siteConfig.isDev;
  }

  async _fetch(route, method, body) {
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

    const opts : any = {
      method,
      headers: Object.assign(this.headers),
      credentials: 'same-origin', // Needed for older versions of Firefox, otherwise cookies not sent
    };
    if (body) {
      opts.body = JSON.stringify(body);
    }
    return fetch(fullRoute, opts);
  }

  GET(route) { return this._fetch(route, "GET", null); }

  POST(route, body) { return this._fetch(route, "POST", body); }

  PUT(route, body) { return this._fetch(route, "PUT", body); }

  PATCH(route, body) { return this._fetch(route, "PATCH", body); }

  DELETE(route) { return this._fetch(route, "DELETE", null); }

  saveLayout = (id, layout) => {
    if (!this.isDev) {
      const strippedLayout = layout.map(widget => ({ ...widget, moved: undefined }));
      return this.PUT(`/dashboard/${id}`, strippedLayout);
    }
  };

  createWidget = async type => {
    const response = this.isDev ? await this.GET(`/widget/create.json?type=${type}`) : await this.POST(`/widget?type=${type}`, null);
    return await response.json();
  };

  getWidgetHtml = async id => {
    const html = this.isDev ? await this.GET(`/widget/${id}/create`) : await this.GET(`/widget/${id}`);
    return html.text();
  };

  deleteWidget = id => !this.isDev && this.DELETE(`/widget/${id}`);

  getEditForm = async id => {
    const response = await this.GET(`/widget/${id}/edit`);
    return response.json();
  };

  saveWidget = async (url, params) => {
    const result = this.isDev ? await this.GET(`/widget/update.json`) : await this.PUT(`${url}`, params);
    return await result.json();
  };
}
