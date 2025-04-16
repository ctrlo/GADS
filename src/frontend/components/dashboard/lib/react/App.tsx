import React, { useEffect, useRef } from "react";

import Header from "./Header";
import Footer from "./Footer";
import { sidebarObservable } from 'components/sidebar/lib/sidebarObservable';
import DashboardView from "./Dashboard/DashboardView";
import EditModal from "./EditModal/EditModal";

import { AppProps } from "./types"
import serialize from "form-serialize";
import { initializeRegisteredComponents } from "component";

function App(props: AppProps) {
  const formRef = useRef<HTMLDivElement>(null);

  const [editModalOpen, setEditModalOpen] = React.useState(false);
  const [editHtml, setEditHtml] = React.useState("");
  const [loadingEditHtml, setLoadingEditHtml] = React.useState(false);
  const [editError, setEditError] = React.useState("");
  const [loading, setLoading] = React.useState(false);
  const [layout, setLayout] = React.useState(props.widgets.map((widget) => widget.config));
  const [widgets, setWidgets] = React.useState(props.widgets);
  const [activeItem, setActiveItem] = React.useState("");

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

  useEffect(()=>{
    initializeComponents();
  }, [layout]);

  const initializeComponents = () => {
    initializeRegisteredComponents(document.body);
    initializeGlobeComponents();
  }

  const updateWidgetHtml = async (id) => {
    const newHtml = await props.api.getWidgetHtml(id);
    const newWidgets = widgets.map(widget => {
      if (widget.config.i === id) {
        return {
          ...widget,
          html: newHtml,
        };
      }
      return widget;
    });
    setWidgets(newWidgets);
  }

  const fetchEditForm = async (id) => {
    const editFormHtml = await props.api.getEditForm(id);
    if (editFormHtml.is_error) {
      setLoadingEditHtml(false);
      setEditError(editFormHtml.message);
      return;
    }
    setLoadingEditHtml(false);
    setEditError("");
    setEditHtml(editFormHtml.content);
  }

  const onEditClick = id => (event) => {
    event.preventDefault();
    showEditForm(id);
  }

  const showEditForm = (id) => {
    setEditModalOpen(true);
    setLoadingEditHtml(true)
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

    setWidgets(widgets.filter(item => item.config.i !== activeItem)),
      setEditModalOpen(false);
    props.api.deleteWidget(activeItem);
  }

  const saveActiveWidget = async (event) => {
    event.preventDefault();
    const formEl = formRef.current.querySelector("form");
    if (!formEl) {
      // eslint-disable-next-line no-console
      console.error("No form element was found!");
      return;
    }

    const form = serialize(formEl, { hash: true });
    const result = await props.api.saveWidget(formEl.getAttribute("action"), form);
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
      if ((x + w) < props.gridConfig.cols) {
        x += 1;
      } else {
        const x = 0;
        y += 1;
      }
      if (y > 200) break;
    }
    return { x, y };
  }

  // eslint-disable-next-line no-unused-vars
  const addWidget = async (type) => {
    setLoading(true);
    const result = await props.api.createWidget(type)
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
    setWidgets(widgets.concat({
      config: widgetLayout,
      html: "Loading...",
    }));
    setLayout(newLayout);
    setLoading(false);
    props.api.saveLayout(props.dashboardId, newLayout);
    showEditForm(id);
  }

  const onLayoutChange = (newLayout) => {
    if (shouldSaveLayout(layout, newLayout)) {
      props.api.saveLayout(props.dashboardId, newLayout);
    }
    setLayout(newLayout);
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

  const handleSideBarChange = () => {
    window.dispatchEvent(new Event('resize'));
  }

  const initializeSummernoteComponent = () => {
    const summernoteEl = formRef.current.querySelector('.summernote');
    if (summernoteEl) {
      import(/* WebpackChunkName: "summernote" */ "../../../summernote/lib/component")
        .then(({ default: SummerNoteComponent }) => {
          new SummerNoteComponent(summernoteEl as HTMLElement)
        });
    }
  }

  const initializeGlobeComponents = () => {
    const arrGlobe = document.querySelectorAll(".globe");
    import(/* WebpackChunkName: "globe" */ '../../../globe/lib/component').then(({ default: GlobeComponent }) => {
      arrGlobe.forEach((globe) => {
        new GlobeComponent(globe as HTMLElement)
      });
    });
  }

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

export default App;
