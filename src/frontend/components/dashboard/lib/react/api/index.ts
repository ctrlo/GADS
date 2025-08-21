import { Layout } from 'react-grid-layout';
import { ApiResponse } from '../types';

/**
 * Request method types for the API client.
 */
type RequestMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';

/**
 * ApiClient class for making API requests.
 */
export default class ApiClient {
    private headers: Record<string, string> = {};
    private isDev: boolean;

    /**
     * Create an instance of ApiClient.
     * @param {string} [baseUrl = ''] Base URL for the API requests.
     */
    constructor(private baseUrl: string = '') {
        this.headers = {};
        // @ts-expect-error "isDev is not valid"
        this.isDev = window.siteConfig && window.siteConfig.isDev;
    }

    /**
     * Perform a fetch request to the API.
     * @description This method constructs a fetch request with the specified route, method, and body.
     * @template T The type of the object to be sent in the request body.
     * @param {string} route The API route to fetch.
     * @param {RequestMethod} method The HTTP method to use for the request.
     * @param {T} body The body of the request, if applicable.
     * @returns {Promise<Response>} A promise that resolves to the response of the fetch request.
     */
    async _fetch<T extends object = object>(route: string, method: RequestMethod, body?: T): Promise<Response> {
        if (!route) throw new Error('Route is undefined');

        let csrfParam = '';
        if (method === 'POST' || method === 'PUT' || method === 'DELETE') {
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
     * Perform a GET request to the API.
     * @param {string} route The API route to fetch.
     * @returns {Promise<Response>} A promise that resolves to the response of the fetch request.
     */
    GET(route: string): Promise<Response> { return this._fetch(route, 'GET', null); }

    /**
     * Perform a POST request to the API.
     * @template T The type of the object to be sent in the request body.
     * @param {string} route The API route to fetch.
     * @param {T} body The body of the request
     * @returns {Promise<Response>} A promise that resolves to the response of the fetch request.
     */
    POST(route: string, body: any): Promise<Response> { return this._fetch(route, 'POST', body); }

    /**
     * Perform a PUT request to the API.
     * @template T The type of the object to be sent in the request body.
     * @param {string} route The API route to fetch.
     * @param {T} body The body of the request
     * @returns {Promise<Response>} A promise that resolves to the response of the fetch request.
     */
    PUT(route: string, body: any): Promise<Response> { return this._fetch(route, 'PUT', body); }

    /**
     * Perform a DELETE request to the API.
     * @param {string} route The API route to fetch.
     * @returns {Promise<Response>} A promise that resolves to the response of the fetch request.
     */
    DELETE(route: string): Promise<Response> { return this._fetch(route, 'DELETE', null); }

    /**
     * Save the layout of a dashboard.
     * @param {string} id The ID of the dashboard to save the layout for.
     * @param {Layout[]} layout The layout to save, which is an array of widgets.
     * @returns {Promise<Response> } A promise that resolves to the response of the fetch request.
     */
    saveLayout = (id: string, layout: Layout[]) => {
        if (!this.isDev) {
            const strippedLayout = layout.map(widget => ({ ...widget, moved: undefined }));
            return this.PUT(`/dashboard/${id}`, strippedLayout);
        }
    };

    /**
     * Create a widget
     * @param {string} type The type of widget to create.
     * @returns {Promise<ApiResponse>} A promise that resolves to the response of the widget creation request.
     */
    createWidget = async (type: string): Promise<ApiResponse> => {
        const response = this.isDev ? await this.GET(`/widget/create.json?type=${type}`) : await this.POST(`/widget?type=${type}`, null);
        return await response.json();
    };

    /**
     * Get the HTML content of a widget.
     * @param id The ID of the widget to get HTML for.
     * @returns {Promise<string>} The HTML content of the widget.
     */
    getWidgetHtml = async (id: string): Promise<string> => {
        const html = this.isDev ? await this.GET(`/widget/${id}/create`) : await this.GET(`/widget/${id}`);
        return html.text();
    };

    /**
     * Delete a widget.
     * @param {string} id The ID of the widget to delete.
     * @returns {Promise<Response>} A promise that resolves to the response of the delete request.
     */
    deleteWidget = (id: string): Promise<Response> => !this.isDev && this.DELETE(`/widget/${id}`);

    /**
     * Get the edit form for a widget.
     * @param {string} id The ID of the widget to get the edit form for.
     * @returns {Promise<ApiResponse>} A promise that resolves to the JSON response of the edit form.
     */
    getEditForm = async (id: string): Promise<ApiResponse> => {
        const response = await this.GET(`/widget/${id}/edit`);
        return response.json();
    };

    /**
     * Save a widget.
     * @param url The URL to save the widget.
     * @param params The parameters to send with the request.
     * @returns {Promise<ApiResponse>} A promise that resolves to the JSON response of the save widget request.
     */
    saveWidget = async (url: string, params: any): Promise<ApiResponse> => {
        const result = this.isDev ? await this.GET('/widget/update.json') : await this.PUT(`${url}`, params);
        return await result.json();
    };
}
