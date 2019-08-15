export default class ApiClient {
  private baseUrl;
  private headers;

  constructor(baseUrl = "") {
    this.baseUrl = baseUrl;
    this.headers = {};
  }

  async _fetch(route, method, body) {
    if (!route) throw new Error("Route is undefined");

    const fullRoute = `${this.baseUrl}${route}`;

    const opts = {
      method,
      headers: Object.assign(this.headers),
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

  saveLayout = (i, layout) => {
    const strippedLayout = layout.map(w => ({ ...w, moved: undefined }));
    return this.POST(`/dashboard/${i}`, strippedLayout);
  }

  createWidget = type => this.POST(`/widget?type=${type}`, null)

  getWidgetHtml = i => this.GET(`/widget/${i}`)

  deleteWidget = i => this.DELETE(`/widget/${i}`)

  getEditFormHtml = async (i) => {
    const html = await this.GET(`/widget/${i}/edit`);
    return html.text();
  }

  saveWidget = (url, params) => this.PUT(`${url}?${params}`, null)
}
