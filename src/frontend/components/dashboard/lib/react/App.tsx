import React, { Component } from "react";

import Header from "./Header";
import Footer from "./Footer";
import { sidebarObservable } from "components/sidebar/lib/sidebarObservable";
import DashboardView from "./Dashboard/DashboardView";
import EditModal from "./EditModal/EditModal";

import { AppProps } from "./types";
import serialize from "form-serialize";
import { initializeRegisteredComponents } from "component";

type AppState = {
    editModalOpen: boolean;
    editHtml: string;
    loadingEditHtml: boolean;
    editError: string;
    loading: boolean;
    layout: any[];
    widgets: any[];
    activeItem: string;
};


/**
 * Application class for the dashboard entry point
 */
export default class App extends Component<AppProps, AppState> {
    private formRef = React.createRef<HTMLDivElement>();

    /**
     * Constructor for the application class
     * @param props The application properties
     */
    constructor(props: AppProps) {
        super(props);
        this.state = {
            editModalOpen: false,
            editHtml: "",
            loadingEditHtml: false,
            editError: "",
            loading: false,
            layout: props.widgets.map((widget) => widget.config),
            widgets: props.widgets,
            activeItem: ""
        };
        sidebarObservable.addSubscriber(this);
        this.initializeGlobeComponents();
    }

    /**
     * @inheritdoc
     */
    componentDidUpdate(prevProps: Readonly<AppProps>, prevState: Readonly<AppState>): void {
        if (prevState.layout !== this.state.layout) {
            this.initializeGlobeComponents();
        }
        if (this.state.editModalOpen && !this.state.loadingEditHtml && this.formRef) {
            this.initializeSummernoteComponent();
            if (this.formRef.current) {
                initializeRegisteredComponents(this.formRef.current);
            }
        }

        if (!this.state.editModalOpen && !this.state.loadingEditHtml) {
            initializeRegisteredComponents(document.body);
        }
    }

    /**
     * Initialize the Summernote component if it exists in the form
     */
    private initializeSummernoteComponent() {
        if (!this.formRef.current) return;
        const summernoteEl = this.formRef.current.querySelector(".summernote");
        if (summernoteEl) {
            import(/* WebpackChunkName: "summernote" */ "../../../summernote/lib/component")
                .then(({ default: SummerNoteComponent }) => {
                    new SummerNoteComponent(summernoteEl as HTMLElement);
                });
        }
    }

    /**
     * Initialize the Globe components if they exist in the DOM
     */
    private initializeGlobeComponents = () => {
        const arrGlobe = document.querySelectorAll(".globe");
        import(/* WebpackChunkName: "globe" */ "../../../globe/lib/component").then(({ default: GlobeComponent }) => {
            arrGlobe.forEach((globe) => {
                new GlobeComponent(globe as HTMLElement);
            });
        });
    };

    /**
     * Overwrite the submit event listener for the form
     */
    private overWriteSubmitEventListener = () => {
        const formContainer = document.getElementById("ld-form-container");
        if (!formContainer) return;

        const form = formContainer.querySelector("form");
        if (!form) return;

        form.addEventListener("submit", this.saveActiveWidget);
        const submitButton = document.createElement("input");
        submitButton.setAttribute("type", "submit");
        submitButton.setAttribute("style", "visibility: hidden");
        form.appendChild(submitButton);
    };

    /**
     * Handle sidebar changes
     */
    private handleSideBarChange = () => {
        window.dispatchEvent(new Event("resize"));
    };

    /**
     * Update the HTML of a widget
     * @param {string} id The ID of the widget to update
     */
    private updateWidgetHtml = async (id: string) => {
        const newHtml = await this.props.api.getWidgetHtml(id, this.props.currentId);
        const newWidgets = this.state.widgets.map(widget => {
            if (widget.config.i === id) {
                return {
                    ...widget,
                    html: newHtml
                };
            }
            return widget;
        });
        this.setState({ widgets: newWidgets }, () => initializeRegisteredComponents(document.body));
    };

    /**
     * Fetch the edit form HTML for a widget
     * @param {string} id The ID of the widget to fetch the edit form for
     */
    private fetchEditForm = async (id: string) => {
        const editFormHtml = await this.props.api.getEditForm(id);
        if (editFormHtml.is_error) {
            this.setState({ loadingEditHtml: false, editError: editFormHtml.message });
            return;
        }
        this.setState({ loadingEditHtml: false, editError: "", editHtml: editFormHtml.content }, ()=>initializeRegisteredComponents(this.formRef.current));
    };

    /**
     * Action for the on edit click event
     * @param {string} id The ID of the widget to edit
     */
    private onEditClick = (id: string) => {
        return (event: React.MouseEvent) => {
            event.preventDefault();
            this.showEditForm(id);
        };
    };

    /**
     * Show the edit form for a widget
     * @param {string} id The ID of the widget to show the edit form for
     */
    private showEditForm = (id: string) => {
        this.setState({
            editModalOpen: true,
            loadingEditHtml: true,
            activeItem: id
        });
        this.fetchEditForm(id);
    };

    /**
     * Close the edit modal
     */
    private closeModal = () => {
        this.setState({ editModalOpen: false });
    };

    /**
     * Delete the active widget
     */
    private deleteActiveWidget = () => {
        if (!window.confirm("Deleting a widget is permanent! Are you sure?")) return;

        this.setState({
            widgets: this.state.widgets.filter(item => item.config.i !== this.state.activeItem),
            editModalOpen: false
        }, () => initializeRegisteredComponents(document.body));
        this.props.api.deleteWidget(this.state.activeItem);
    };

    /**
     * Save the active widget
     * @param {*} event The submit event
     */
    private saveActiveWidget = async (event: any) => {
        event.preventDefault();
        const formEl = this.formRef.current.querySelector("form");
        if (!formEl) {
            console.error("No form element was found!");
            return;
        }

        const form = serialize(formEl, { hash: true });
        const result = await this.props.api.saveWidget(formEl.getAttribute("action"), form);
        if (result.is_error) {
            this.setState({ editError: result.message });
            return;
        }
        this.updateWidgetHtml(this.state.activeItem);
        this.closeModal();
    };

    /**
     * Check if the placement conflicts with existing widgets
     * @param {number} x The x-coordinate of the widget
     * @param {number} y The y-coordinate of the widget
     * @param {number} w The width of the widget
     * @param {number} h The height of the widget
     * @returns {boolean} Whether the grid conflicts with existing widgets
     */
    private isGridConflict = (x: number, y: number, w: number, h: number): boolean => {
        const ulc = { x, y };
        const drc = { x: x + w, y: y + h };
        return this.state.layout.some((widget) => {
            if (ulc.x >= (widget.x + widget.w) || widget.x >= drc.x) {
                return false;
            }
            if (ulc.y >= (widget.y + widget.h) || widget.y >= drc.y) {
                return false;
            }
            return true;
        });
    };

    /**
     * Get the first available position for a widget
     * @param {number} w The width of the widget
     * @param {number} h The height of the widget
     * @returns {{ x: number, y: number }} The first available position for the widget
     */
    private firstAvailableSpot = (w: number, h: number): { x: number; y: number; } => {
        let x = 0;
        let y = 0;
        while (this.isGridConflict(x, y, w, h)) {
            if ((x + w) < this.props.gridConfig.cols) {
                x += 1;
            } else {
                y += 1;
            }
            if (y > 200) break;
        }
        return { x, y };
    };

    /**
     * Add a new widget to the dashboard
     * @param {string} type The type of widget to add
     */
    private addWidget = async (type: string) => {
        this.setState({ loading: true });
        const result = await this.props.api.createWidget(type);
        if (result.error) {
            this.setState({ loading: false });
            alert(result.message);
            return;
        }
        const id = result.message;
        const { x, y } = this.firstAvailableSpot(1, 1);
        const widgetLayout = {
            i: id,
            x,
            y,
            w: 1,
            h: 1
        };
        const newLayout = this.state.layout.concat(widgetLayout);
        this.setState({
            widgets: this.state.widgets.concat({
                config: widgetLayout,
                html: "Loading...",
                layout: newLayout,
                loading: false
            })
        });
        this.setState({ layout: newLayout, loading: false }, () => initializeRegisteredComponents(document.body));
        this.props.api.saveLayout(this.props.dashboardId, newLayout);
        this.showEditForm(id);
    };

    /**
     * Triggered when the layout of the dashboard changes
     * @param {*} newLayout The new layout of the dashboard
     */
    private onLayoutChange = (newLayout: any) => {
        if (this.shouldSaveLayout(this.state.layout, newLayout)) {
            this.props.api.saveLayout(this.props.dashboardId, newLayout);
        }
        this.setState({ layout: newLayout }, () => initializeRegisteredComponents(document.body));
    };

    /**
     * Check if the layout should be saved
     * @param {*} prevLayout The previous layout of the dashboard
     * @param {*} newLayout The new layout of the dashboard
     * @returns {boolean} Whether the layout should be saved
     */
    private shouldSaveLayout = (prevLayout: any, newLayout: any): boolean => {
        if (prevLayout.length !== newLayout.length) {
            return true;
        }
        for (let i = 0; i < prevLayout.length; i += 1) {
            const entriesNew = Object.entries(newLayout[i]);
            const isDifferent = entriesNew.some((keypair) => {
                const [key, value] = keypair;
                if (key === "moved" || key === "static") return false;
                if (value !== prevLayout[i][key]) return true;
                return false;
            });
            if (isDifferent) return true;
        }
        return false;
    };

    /**
     * Render the application component
     */
    render() {
        return (
            <div className="content-block">
                {this.props.hideMenu || <Header
                    hMargin={this.props.gridConfig.containerPadding[0]}
                    dashboards={this.props.dashboards}
                    currentDashboard={this.props.currentDashboard}
                    includeH1={this.props.includeH1}
                />}
                <EditModal
                    closeModal={this.closeModal}
                    deleteActiveWidget={this.deleteActiveWidget}
                    editError={this.state.editError}
                    editHtml={this.state.editHtml}
                    editModalOpen={this.state.editModalOpen}
                    formRef={this.formRef}
                    loadingEditHtml={this.state.loadingEditHtml}
                    saveActiveWidget={this.saveActiveWidget} />
                <DashboardView
                    gridConfig={this.props.gridConfig}
                    layout={this.state.layout}
                    onEditClick={this.onEditClick}
                    onLayoutChange={this.onLayoutChange}
                    readOnly={this.props.readOnly}
                    widgets={this.state.widgets} />
                {this.props.hideMenu || <Footer
                    addWidget={this.addWidget}
                    widgetTypes={this.props.widgetTypes}
                    currentDashboard={this.props.currentDashboard}
                    noDownload={this.props.noDownload}
                    readOnly={this.props.readOnly}
                />}
            </div>
        );
    }
}
