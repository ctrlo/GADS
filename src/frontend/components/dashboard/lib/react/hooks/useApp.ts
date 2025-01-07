import { RefObject, useState } from "react";
import { AppProps } from "../types";
import serialize from "form-serialize";

export default function useApp({api, widgets, gridConfig, dashboardId}:AppProps, formRef: RefObject<HTMLDivElement>) {
    const [layout, setLayout] = useState(widgets.map(widget => widget.config));
    const [editModalOpen, setEditModalOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const [loadingEditHtml, setLoadingEditHtml] = useState(false);
    const [myWidgets, setMyWidgets] = useState(widgets);
    const [editError, setEditError] = useState<string>("");
    const [editHtml, setEditHtml] = useState("");
    const [activeItem, setActiveItem] = useState(null);

    const updateWidgetHtml = async (id) => {
        const newHtml = await api.getWidgetHtml(id);
        const newWidgets = myWidgets.map(widget => {
            if (widget.config.i === id) {
                return {
                    ...widget,
                    html: newHtml,
                };
            }
            return widget;
        });
        setMyWidgets(newWidgets);
    }

    const fetchEditForm = async (id) => {
        const editFormHtml = await api.getEditForm(id);
        if (editFormHtml.is_error) {
            setLoadingEditHtml(false);
            setEditError(editFormHtml.message);
            return;
        }
        setLoadingEditHtml(false)
        setEditError(null);
        setEditHtml(editFormHtml.content);
    }

    const onEditClick = id => (event) => {
        console.log("onEditClick", id)
        event.preventDefault();
        showEditForm(id);
    }

    const showEditForm = (id) => {
        setEditModalOpen(true);
        setLoadingEditHtml(true);
        setActiveItem(id);
        fetchEditForm(id);
    }

    const closeModal = () => {
        setEditModalOpen(false);
    }

    const deleteActiveWidget = () => {
        // eslint-disable-next-line no-alert
        if (!window.confirm("Deleting a widget is permanent! Are you sure?"))
            return

        setMyWidgets(myWidgets.filter(item => item.config.i !== activeItem));
        setEditModalOpen(false);
        api.deleteWidget(activeItem);
    }

    const saveActiveWidget = async (event) => {
        event.preventDefault();
        if (!formRef.current) return;
        const formEl = formRef.current.querySelector("form");
        if (!formEl) {
            // eslint-disable-next-line no-console
            console.error("No form element was found!");
            return;
        }

        const form = serialize(formEl, { hash: true });
        const result = await api.saveWidget(formEl.getAttribute("action"), form);
        if (result.is_error) {
            setEditError(result.message);
            return;
        }
        updateWidgetHtml(activeItem);
        closeModal();
    }

    const isGridConflict = (x, y, w, h) => {
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
    }

    const firstAvailableSpot = (w, h) => {
        let x = 0;
        let y = 0;
        while (isGridConflict(x, y, w, h)) {
            if ((x + w) < gridConfig.cols) {
                x += 1;
            } else {
                x = 0;
                y += 1;
            }
            if (y > 200) break;
        }
        return { x, y };
    }

    // eslint-disable-next-line no-unused-vars
    const addWidget = async (type) => {
        setLoading(true);
        const result = await api.createWidget(type)
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
            h: 1,
        };
        const newLayout = layout.concat(widgetLayout);
        setMyWidgets(myWidgets.concat({
            config: widgetLayout,
            html: "Loading...",
        }));
        setLayout(newLayout);
        setLoading(false);
        updateWidgetHtml(id);
        api.saveLayout(dashboardId, newLayout);
        showEditForm(id);
    }

    const onLayoutChange = (newLayout) => {
        if (shouldSaveLayout(layout, newLayout)) {
            api.saveLayout(dashboardId, newLayout);
            setLayout(newLayout);
        }
    }

    const shouldSaveLayout = (prevLayout, newLayout) => {
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
    }

    const overWriteSubmitEventListener = () => {
        const formContainer = document.getElementById("ld-form-container");
        if (!formContainer)
            return

        const form = formContainer.querySelector("form");
        if (!form)
            return

        form.addEventListener("submit", saveActiveWidget);
        const submitButton = document.createElement("input");
        submitButton.setAttribute("type", "submit");
        submitButton.setAttribute("style", "visibility: hidden");
        form.appendChild(submitButton);
    }

    return { editError, editHtml, editModalOpen, layout, loading, loadingEditHtml, myWidgets, closeModal, deleteActiveWidget, saveActiveWidget, onEditClick, onLayoutChange, addWidget };
}