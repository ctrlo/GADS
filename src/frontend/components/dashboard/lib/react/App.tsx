import React, { useEffect, useRef } from 'react';

import Header from './Header';
import Footer from './Footer';
import { sidebarObservable } from 'components/sidebar/lib/sidebarObservable';
import DashboardView from './Dashboard/DashboardView';
import EditModal from './EditModal/EditModal';

import { AppProps } from './types';
import serialize from 'form-serialize';
import { initializeRegisteredComponents } from 'component';

/**
 * Create the application component
 * @param {AppProps} props The application properties
 * @returns {React.JSX.Element} The rendered application component
 */
export default function App(props: AppProps): React.JSX.Element {
    const formRef = useRef<HTMLDivElement>(null);

    const [editModalOpen, setEditModalOpen] = React.useState(false);
    const [editHtml, setEditHtml] = React.useState('');
    const [loadingEditHtml, setLoadingEditHtml] = React.useState(false);
    const [editError, setEditError] = React.useState('');
    const [loading, setLoading] = React.useState(false); // eslint-disable-line @typescript-eslint/no-unused-vars
    const [layout, setLayout] = React.useState(props.widgets.map((widget) => widget.config));
    const [widgets, setWidgets] = React.useState(props.widgets);
    const [activeItem, setActiveItem] = React.useState('');

    useEffect(() => {
        sidebarObservable.addSubscriberFunction(handleSideBarChange);

        initializeGlobeComponents();
    }, []);

    useEffect(() => {
        if (editModalOpen && !loadingEditHtml && formRef) {
            initializeSummernoteComponent();
        }

        if (!editModalOpen && !loadingEditHtml) {
            initializeComponents();
        }
    }, [editModalOpen, loadingEditHtml]);

    useEffect(() => {
        initializeComponents();
    }, [layout]);

    /**
     * Initialize all components that need to be set up
     */
    const initializeComponents = () => {
        initializeRegisteredComponents(document.body);
        initializeGlobeComponents();
    };

    /**
     * Update the HTML of a widget
     * @param {string} id The ID of the widget to update
     */
    const updateWidgetHtml = async (id: string) => {
        const newHtml = await props.api.getWidgetHtml(id);
        const newWidgets = widgets.map(widget => {
            if (widget.config.i === id) {
                return {
                    ...widget,
                    html: newHtml
                };
            }
            return widget;
        });
        setWidgets(newWidgets);
    };

    /**
     * Fetch the edit form HTML for a widget
     * @param {string} id The ID of the widget to fetch the edit form for
     */
    const fetchEditForm = async (id: string) => {
        const editFormHtml = await props.api.getEditForm(id);
        if (editFormHtml.is_error) {
            setLoadingEditHtml(false);
            setEditError(editFormHtml.message);
            return;
        }
        setLoadingEditHtml(false);
        setEditError('');
        setEditHtml(editFormHtml.content);
    };

    /**
     * Action for the on edit click event
     * @param {string} id The ID of the widget to edit
     */
    const onEditClick = (id: string) => (event: React.MouseEvent) => {
        event.preventDefault();
        showEditForm(id);
    };

    /**
     * Show the edit form for a widget
     * @param {string} id The ID of the widget to show the edit form for
     */
    const showEditForm = (id) => {
        setEditModalOpen(true);
        setLoadingEditHtml(true);
        setActiveItem(id);
        fetchEditForm(id);
    };

    /**
     * Close the edit modal
     */
    const closeModal = () => {
        setEditModalOpen(false);
    };

    /**
     * Delete the active widget
     */
    const deleteActiveWidget = () => {
        if (!window.confirm('Deleting a widget is permanent! Are you sure?')) return;

        setWidgets(widgets.filter(item => item.config.i !== activeItem));
        setEditModalOpen(false);
        props.api.deleteWidget(activeItem);
    };

    /**
     * Save the active widget
     * @param {*} event The submit event
     */
    const saveActiveWidget = async (event: any) => {
        event.preventDefault();
        const formEl = formRef.current.querySelector('form');
        if (!formEl) {
            console.error('No form element was found!');
            return;
        }

        const form = serialize(formEl, { hash: true });
        const result = await props.api.saveWidget(formEl.getAttribute('action'), form);
        if (result.is_error) {
            setEditError(result.message);
            return;
        }
        updateWidgetHtml(activeItem);
        closeModal();
    };

    /**
     * Check if the placement conflicts with existing widgets
     * @param {number} x The x-coordinate of the widget
     * @param {number} y The y-coordinate of the widget
     * @param {number} w The width of the widget
     * @param {number} h The height of the widget
     * @returns {boolean} Whether the grid conflicts with existing widgets
     */
    const isGridConflict = (x: number, y: number, w: number, h: number): boolean => {
        const ulc = { x, y };
        const drc = { x: x + w, y: y + h };
        return layout.some((widget) => {
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
    const firstAvailableSpot = (w: number, h: number): { x: number; y: number; } => {
        let x = 0;
        let y = 0;
        while (isGridConflict(x, y, w, h)) {
            if ((x + w) < props.gridConfig.cols) {
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
    const addWidget = async (type: string) => {
        setLoading(true);
        const result = await props.api.createWidget(type);
        if (result.error) {
            setLoading(false);
            alert(result.message);
            return;
        }
        const id = result.message;
        const { x, y } = firstAvailableSpot(1, 1);
        const widgetLayout = {
            i: id,
            x,
            y,
            w: 1,
            h: 1
        };
        const newLayout = layout.concat(widgetLayout);
        setWidgets(widgets.concat({
            config: widgetLayout,
            html: 'Loading...'
        }));
        setLayout(newLayout);
        setLoading(false);
        props.api.saveLayout(props.dashboardId, newLayout);
        showEditForm(id);
    };

    /**
     * Triggered when the layout of the dashboard changes
     * @param {*} newLayout The new layout of the dashboard
     */
    const onLayoutChange = (newLayout: any) => {
        if (shouldSaveLayout(layout, newLayout)) {
            props.api.saveLayout(props.dashboardId, newLayout);
        }
        setLayout(newLayout);
    };

    /**
     * Check if the layout should be saved
     * @param {*} prevLayout The previous layout of the dashboard
     * @param {*} newLayout The new layout of the dashboard
     * @returns {boolean} Whether the layout should be saved
     */
    const shouldSaveLayout = (prevLayout: any, newLayout: any): boolean => {
        if (prevLayout.length !== newLayout.length) {
            return true;
        }
        for (let i = 0; i < prevLayout.length; i += 1) {
            const entriesNew = Object.entries(newLayout[i]);
            const isDifferent = entriesNew.some((keypair) => {
                const [key, value] = keypair;
                if (key === 'moved' || key === 'static') return false;
                if (value !== prevLayout[i][key]) return true;
                return false;
            });
            if (isDifferent) return true;
        }
        return false;
    };

    /**
     * Overwrite the submit event listener for the form
     */
    const overWriteSubmitEventListener = () => { // eslint-disable-line
        const formContainer = document.getElementById('ld-form-container');
        if (!formContainer)
            return;

        const form = formContainer.querySelector('form');
        if (!form)
            return;

        form.addEventListener('submit', saveActiveWidget);
        const submitButton = document.createElement('input');
        submitButton.setAttribute('type', 'submit');
        submitButton.setAttribute('style', 'visibility: hidden');
        form.appendChild(submitButton);
    };

    /**
     * Handle sidebar changes
     */
    const handleSideBarChange = () => {
        window.dispatchEvent(new Event('resize'));
    };

    /**
     * Initialize the Summernote component if it exists in the form
     */
    const initializeSummernoteComponent = () => {
        const summernoteEl = formRef.current.querySelector('.summernote');
        if (summernoteEl) {
            import(/* WebpackChunkName: "summernote" */ '../../../summernote/lib/component')
                .then(({ default: SummerNoteComponent }) => {
                    new SummerNoteComponent(summernoteEl as HTMLElement);
                });
        }
    };

    /**
     * Initialize the Globe components if they exist in the DOM
     */
    const initializeGlobeComponents = () => {
        const arrGlobe = document.querySelectorAll('.globe');
        import(/* WebpackChunkName: "globe" */ '../../../globe/lib/component').then(({ default: GlobeComponent }) => {
            arrGlobe.forEach((globe) => {
                new GlobeComponent(globe as HTMLElement);
            });
        });
    };

    return (
        <div className="content-block">
            {props.hideMenu || <Header
                hMargin={props.gridConfig.containerPadding[0]}
                dashboards={props.dashboards}
                currentDashboard={props.currentDashboard}
                includeH1={props.includeH1}
            />}
            <EditModal
                closeModal={closeModal}
                deleteActiveWidget={deleteActiveWidget}
                editError={editError}
                editHtml={editHtml}
                editModalOpen={editModalOpen}
                formRef={formRef}
                loadingEditHtml={loadingEditHtml}
                saveActiveWidget={saveActiveWidget} />
            <DashboardView
                gridConfig={props.gridConfig}
                layout={layout}
                onEditClick={onEditClick}
                onLayoutChange={onLayoutChange}
                readOnly={props.readOnly}
                widgets={widgets} />
            {props.hideMenu || <Footer
                addWidget={addWidget}
                widgetTypes={props.widgetTypes}
                currentDashboard={props.currentDashboard}
                noDownload={props.noDownload}
                readOnly={props.readOnly}
            />}
        </div>
    );
}
