type ApiMethod = "GET" | "POST" | "PUT" | "DELETE";

/**
 * ApiClient is a class that provides methods to make HTTP requests to a given base URL.
 * It supports GET, POST, PUT, PATCH, and DELETE methods.
 */
export default class ApiClient {
  private readonly headers: any;
  private readonly isDev: boolean;

  /**
   * Create a new ApiClient instance.
   * @param baseUrl The base URL for the API requests. Default is an empty string.
   */
  constructor(private baseUrl: string = "") {
    this.headers = {};
    // @ts-expect-error "isDev is not valid"
    this.isDev = window.siteConfig && window.siteConfig.isDev
  }

  /**
   * Wrapper for the fetch API to allow for CSRF to be included.
   * @template T The type of the body to send with the request.
   * @param route The route to fetch.
   * @param method The HTTP method to use (GET, POST, PUT, PATCH, DELETE).
   * @param body The body to send with the request (optional).
   * @throws Will throw an error if the route is undefined.
   * @returns A Promise that resolves to the Response object.
   */
  async _fetch<T extends object>(route: string, method: ApiMethod, body?: T): Promise<Response> {
    if (!route) throw new Error("Route is undefined");

    let csrfParam = "";
    if (method === "POST" || method === "PUT" || method === "DELETE") {
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

  /**
   * Perform a GET request to the specified route.
   * @param route The route to fetch.
   * @returns A Promise that resolves to the Response object.
   */
  GET(route: string) { return this._fetch(route, "GET"); }

  /**
   * Perform a POST request to the specified route.
   * @param route The route to fetch.
   * @param body The body to send with the request.
   * @returns A Promise that resolves to the Response object.
   * @template T The type of the body to send with the request.
   */
  POST<T extends object>(route: string, body: T) { return this._fetch(route, "POST", body); }

  /**
   * Perform a PUT request to the specified route.
   * @param route The route to fetch.
   * @param body The body to send with the request.
   * @returns A Promise that resolves to the Response object.
   * @template T The type of the body to send with the request.
   */
  PUT<T extends object>(route: string, body: T) { return this._fetch(route, "PUT", body); }

  /**
   * Perform a DELETE request to the specified route.
   * @param route The route to fetch.
   * @returns A Promise that resolves to the Response object.
   */
  DELETE(route: string) { return this._fetch(route, "DELETE"); }

  /**
   * Save the layout to the server.
   * @param id The identifier of the layout to save.
   * @param layout The layout to save.
   * @returns A Promise that resolves to the Response object.
   */
  saveLayout = (id: string, layout: any) => {
    if (!this.isDev) {
      const strippedLayout = layout.map((widget: any) => ({ ...widget, moved: undefined }));
      return this.PUT(`/dashboard/${id}`, strippedLayout);
    }
  }

  /**
   * Create a widget for the dashboard
   * @param type The type of widget to create.
   * @returns A response object containing the created widget.
   */
  createWidget = async (type: string) => {
    const response = this.isDev ? await this.GET(`/widget/create.json?type=${type}`) : await this.POST(`/widget?type=${type}`, null)
    return await response.json()
  }

  /**
   * Get the widget HTML from the server
   * @param id The identifier of the widget to get.
   * @returns An HTML string containing the widget.
   */
  getWidgetHtml = async (id: string) => {
    const html = this.isDev ? await this.GET(`/widget/${id}/create`) : await this.GET(`/widget/${id}`)
    return html.text();
  }

  /**
   * Delete a widget from the dashboard
   * @param id The identifier of the widget to delete.
   * @returns A Promise that resolves to the Response object.
   */
  deleteWidget = (id: string) => !this.isDev && this.DELETE(`/widget/${id}`)

  /**
   * Get the edit form for a widget
   * @param id The identifier of the widget to get the edit form for.
   * @returns The JSON response containing the edit form.
   */
  getEditForm = async (id: string) => {
    const response = await this.GET(`/widget/${id}/edit`);
    return response.json();
  }

  /**
   * Save a widget to the server
   * @param url The URL to save the widget to.
   * @param params The widget parameters to save.
   * @returns The JSON response containing the saved widget.
   */
  saveWidget = async (url: string, params: any) => {
    const result = this.isDev ? await this.GET(`/widget/update.json`) : await this.PUT(`${url}`, params);
    return await result.json();
  }
}
