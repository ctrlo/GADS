'use client';

import React, { useEffect, useRef } from "react";
import serialize from "form-serialize";

import Modal from "react-modal";
import RGL, { WidthProvider } from "react-grid-layout";

import Header from "./Header";
import Footer from "./Footer";
import { sidebarObservable } from '../../../sidebar/lib/sidebarObservable';
import { AppState, Widget } from "./interfaces/interfaces";
import { compare } from "util/common";
import Dashboard from "./Dashboard";

declare global {
  interface Window {
    Linkspace: any,
    // @ts-expect-error "Typings clash with JSTree"
    siteConfig: any
  }
}

const ReactGridLayout = WidthProvider(RGL);

const modalStyle: Modal.Styles = {
  content: {
    minWidth: "350px",
    maxWidth: "80vw",
    maxHeight: "90vh",
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)",
    msTransform: "translate(-50%, -50%)",
    padding: 0
  },
  overlay: {
    zIndex: 1030,
    background: "rgba(0, 0, 0, .15)"
  }
};

export default function App(state: AppState) {
  const formRef = useRef<HTMLDivElement>();
  const api = state.api;

  const config = {
    cols: 2,
    margin: [32, 32],
    containerPadding: [0, 10],
    rowHeight: 80,
  }

  Modal.setAppElement("#ld-app");

  const [widgets, setWidgets] = React.useState<Widget[]>(state.widgets);
  const [loadingEditHtml, setLoadingEditHtml] = React.useState(false);
  const [editError] = React.useState<string>("");
  const [editHtml, setEditHtml] = React.useState<string>("");
  const [modalOpen, setModalOpen] = React.useState(false);
  const [activeItem, setActiveItem] = React.useState<string>("");
  // eslint-disable-next-line
  const [loading, setLoading] = React.useState(false);
  // eslint-disable-next-line

  const initializeGlobeComponents = () => {
    const arrGlobe = document.querySelectorAll(".globe");
    import('../../../globe/lib/component').then(({ default: GlobeComponent }) => {
      arrGlobe.forEach((globe) => {
        new GlobeComponent(globe)
      });
    });
  }

  const initializeSummernoteComponent = () => {
    const summernoteEl = formRef.current.querySelector('.summernote');
    if (summernoteEl) {
      import(/* WebpackChunkName: "summernote" */ "../../../summernote/lib/component")
        .then(({ default: SummerNoteComponent }) => new SummerNoteComponent(summernoteEl));
    }
  };

  const handleSideBarChange = () => {
    window.dispatchEvent(new Event('resize'));
  };

  useEffect(() => {
    sidebarObservable.addSubscriber({ handleSideBarChange });
    initializeGlobeComponents();
  }, [])

  useEffect(() => {
    if (modalOpen && !loadingEditHtml && formRef.current) {
      initializeSummernoteComponent();
    } else if (!modalOpen && !loadingEditHtml) {
      initializeGlobeComponents();
    }
  }, [modalOpen, loadingEditHtml]);

  useEffect(() => {
    console.log("Widgets", widgets);
  }, [widgets]);

  const updateWidgetHtml = async (id:string) => {
    console.log("Updating widget", id);
    const newHtml = await api.getWidgetHtml(id);
    const newWidgets = widgets.map((widget:Widget) => {
      if (widget.config.i === id) {
        return {
          config: widget.config,
          html: newHtml,
        };
      }
      return widget;
    });
    setWidgets(newWidgets);
  };

  const fetchEditForm = async (id:string) => {
    console.log("Fetching edit form", id);
    const editFormHtml = await api.getEditForm(id);
    if (editFormHtml.is_error) {
      setLoadingEditHtml(false);
      return;
    }
    setLoadingEditHtml(false);
    setEditHtml(editFormHtml.content);
  };

  const onEditClick = (id:string) => (event:React.MouseEvent) => {
    console.log("Edit click", id);
    event.preventDefault();
    showEditForm(id);
  };

  const showEditForm = (id:string) => {
    console.log("Showing edit form", id);
    setModalOpen(true);
    setLoadingEditHtml(true);
    setActiveItem(id);
    fetchEditForm(id);
  };

  const closeModal = () => setModalOpen(false);

  const deleteActiveWidget = () => {
    console.log("Deleting widget", activeItem);
    // eslint-disable-next-line no-alert
    if (!window.confirm("Deleting a widget is permanent! Are you sure?"))
      return

    setWidgets(widgets.filter(item => item.config.i !== activeItem));
    setModalOpen(false);
    api.deleteWidget(activeItem);
  }

  const saveActiveWidget = async (event) => {
    console.log("Saving widget", activeItem);
    event.preventDefault();
    const formEl = formRef.current.querySelector("form");
    if (!formEl) {
      // eslint-disable-next-line no-console
      console.error("No form element was found!");
      return;
    }

    const form = serialize(formEl, { hash: true });
    const result = await api.saveWidget(formEl.getAttribute("action"), form);
    if (result.is_error) {
      // eslint-disable-next-line no-console
      console.error(result.message);
      return;
    }

    updateWidgetHtml(activeItem);
    closeModal();
  }

  const isGridConflict = (x: number, y: number, w: number, h: number): boolean => {
    console.log("Checking grid conflict", x, y, w, h);
    const ulc = { x, y };
    const drc = { x: x + w, y: y + h };

    return widgets.some((widget: any) => {
      if (ulc.x >= (widget.x + widget.h) || widget.x >= drc.x) {
        return false;
      }
      return !(ulc.y >= (widget.y + widget.h) || widget.y >= drc.y);
    })
  }

  const firstAvailableSpot = (w: number, h: number) => {
    console.log("Finding first available spot", w, h);
    let x = 0;
    let y = 0;
    while (isGridConflict(x, y, w, h)) {
      if ((x + w) < config.cols) {
        x += 1;
      } else {
        x = 0;
        y += 1;
      }
      if (y > 200) break;
    }
    return { x, y };
  }

  const addWidget = async (type: string) => {
    console.log("Adding widget", type);
    setLoading(true);
    const result = await api.createWidget(type)
    if (result.error) {
      setLoading(false);
      alert(result.message);
      return;
    }

    const id = result.message;
    const { x, y } = firstAvailableSpot(1, 1);
    const widgetLayout: Widget = {
      config: {
        i: id,
        x,
        y,
        w: 1,
        h: 1
      },
      html: "<p>Loading...</p>",
    };

    const newLayout = widgets.concat(widgetLayout);
    setWidgets(newLayout);
    setLoading(false);
    updateWidgetHtml(id);
    await api.saveLayout(state.dashboardId, newLayout);
    showEditForm(id);
  }

  const onLayoutChange = (layout:RGL.Layout[]) => {
    console.log("Layout change", layout);
    if (shouldSaveLayout(widgets.map(widget=>widget.config), layout)) {
      api.saveLayout(state.dashboardId, layout);
    }
    setWidgets(widgets.map((widget, index) => {
      return {
        config: layout[index],
        html: widget.html,
      }
    }));
  };

  const shouldSaveLayout = (prevLayout: RGL.Layout[], newLayout: RGL.Layout[]): boolean => {
    console.log("Checking if layout should be saved", prevLayout, newLayout);
    if (prevLayout.length !== newLayout.length) {
      return true
    }
    for (let i = 0; i < prevLayout.length; i++) {
      if (prevLayout[i] && newLayout[i] && !compare(prevLayout[i], newLayout[i])) {
        return true;
      }
    }
    return false;
  };

  return (
    <div className="content-block">
      {!state.hideMenu && (<Header
        currentDashboard={state.currentDashboard}
        dashboards={state.dashboards}
        hMargin={config.containerPadding[0]}
        includeH1={true}
        loading={loading} />)}
      <Dashboard
        widgets={widgets}
        config={config}
        modalOpen={modalOpen}
        closeModal={closeModal}
        editError={editError}
        loadingEditHtml={loadingEditHtml}
        editHtml={editHtml}
        deleteActiveWidget={deleteActiveWidget}
        saveActiveWidget={saveActiveWidget}
        readOnly={state.readOnly}
        layoutChange={onLayoutChange}
        />
      {!state.hideMenu && (<Footer
        addWidget={addWidget}
        widgetTypes={state.widgetTypes}
        currentDashboard={state.currentDashboard} // I'm going to modify this so it's dynamic to switch I think?
        noDownload={state.noDownload}
        readOnly={state.readOnly}
        />
      )}
    </div>
  );
}
