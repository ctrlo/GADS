/**
 * API Client for interacting with the backend services.
 * @todo Cleanup
 */
export default class ApiClient {
    private baseUrl;
    private headers;
    private isDev;

    /**
     * Creates a new instance of ApiClient.
     * @param {string} baseUrl Base URL for the API endpoints.
     */
    constructor(baseUrl: string = '') {
        this.baseUrl = baseUrl;
        this.headers = {};
        // @ts-expect-error "isDev is not valid"
        this.isDev = window.siteConfig && window.siteConfig.isDev;
    }

    /**
     * Execute a fetch request to the API.
     * @description This is a basic wrapper around the fetch API.
     * @param {string} route The API route to fetch.
     * @param { 'GET'|'POST'|'PUT'|'PATCH'|'DELETE' } method The API method (GET, POST, PUT, PATCH, DELETE).
     * @param {*} body The body of the request, if applicable.
     * @returns {Promise<Response>} The response from the fetch call.
     */
    async _fetch(route: string, method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE', body: any): Promise<Response> {
        if (!route) throw new Error('Route is undefined');

        let csrfParam = '';
        if (method === 'POST' || method === 'PUT' || method === 'PATCH' || method === 'DELETE') {
            const body = document.querySelector('body');
            const csrfToken = body ? body.getAttribute('data-csrf') : null;
            if (csrfToken) {
                csrfParam = route.indexOf('?') > -1 ? `&csrf-token=${csrfToken}` : `?csrf-token=${csrfToken}`;
            }
        }

        const fullRoute = `${this.baseUrl}${route}${csrfParam}`;

        const opts: any = {
            method,
            headers: Object.assign(this.headers),
            credentials: 'same-origin' // Needed for older versions of Firefox, otherwise cookies not sent
        };
        if (body) {
            opts.body = JSON.stringify(body);
        }
        return fetch(fullRoute, opts);
    }

    /**
     * Performs a GET request to the specified route.
     * @param {string} route The API route to fetch.
     * @returns {Promise<Response>} The response from the fetch call.
     */
    GET(route: string): Promise<Response> { return this._fetch(route, 'GET', null); }

    /**
     * Performs a POST request to the specified route.
     * @param {string} route The API route to fetch.
     * @param {*} body The body of the request, if applicable.
     * @returns {Promise<Response>} The response from the fetch call.
     */
    POST(route: string, body: any): Promise<Response> { return this._fetch(route, 'POST', body); }

    /**
     * Performs a PUT request to the specified route.
     * @param {string} route The API route to fetch.
     * @param {*} body The body of the request, if applicable.
     * @returns {Promise<Response>} The response from the fetch call.
     */
    PUT(route: string, body: any): Promise<Response> { return this._fetch(route, 'PUT', body); }

    /**
     * Performs a PATCH request to the specified route.
     * @param {string} route The API route to fetch.
     * @param {*} body The body of the request, if applicable.
     * @returns {Promise<Response>} The response from the fetch call.
     */
    PATCH(route: string, body: any): Promise<Response> { return this._fetch(route, 'PATCH', body); }

    /**
     * Performs a DELETE request to the specified route.
     * @param {string} route The API route to fetch.
     * @returns {Promise<Response>} The response from the fetch call.
     */
    DELETE(route: string): Promise<Response> { return this._fetch(route, 'DELETE', null); }

    /**
     * Save the layout of a dashboard.
     * @param {string} id The ID of the dashboard to save the layout for.
     * @param {object} layout The layout to save, typically an array of widget configurations.
     * @returns {Promise<Response>} The response from the save operation.
     */
    saveLayout = (id: string, layout: Array<any>): Promise<Response> => {
        if (!this.isDev) {
            const strippedLayout = layout.map(widget => ({ ...widget, moved: undefined }));
            return this.PUT(`/dashboard/${id}`, strippedLayout);
        }
    };

    /**
     * Create a new widget.
     * @param {string} type The type of widget to create.
     * @returns {Promise<Response>} The response from the widget creation request.
     */
    createWidget = async (type: string): Promise<Response> => {
        const response = this.isDev ? await this.GET(`/widget/create.json?type=${type}`) : await this.POST(`/widget?type=${type}`, null);
        return await response.json();
    };

    /**
     * Get the HTML content of a widget.
     * @param {string} id The ID of the widget to retrieve HTML for.
     * @returns {Promise<string>} The HTML content of the widget.
     */
    getWidgetHtml = async (id: string): Promise<string> => {
        const html = this.isDev ? await this.GET(`/widget/${id}/create`) : await this.GET(`/widget/${id}`);
        return html.text();
    };

    /**
     * Delete a widget by its ID.
     * @param {string} id The ID of the widget to delete.
     * @returns {promise<Response>} A promise that resolves when the widget is deleted.
     */
    deleteWidget = (id: string): Promise<Response> => !this.isDev && this.DELETE(`/widget/${id}`);

    /**
     * Get the edit form for a widget.
     * @param {string} id The ID of the widget to retrieve the edit form for.
     * @returns {Promise<object>} The JSON response containing the edit form data for the widget.
     */
    getEditForm = async (id: string): Promise<object> => {
        const response = await this.GET(`/widget/${id}/edit`);
        return response.json();
    };

    /**
     * Save a widget.
     * @param {string} url The URL to save the widget.
     * @param {object} params The parameters to save the widget.
     * @returns {Promise<object>} The JSON response containing the saved widget data.
     */
    saveWidget = async (url, params) => {
        const result = this.isDev ? await this.GET('/widget/update.json') : await this.PUT(`${url}`, params);
        return await result.json();
    };
}
