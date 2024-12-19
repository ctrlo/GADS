'use client';

import React, {useEffect, useRef} from "react";
import serialize from "form-serialize";

import Modal from "react-modal";
import RGL from "react-grid-layout";

import Header from "./Header";
import Footer from "./Footer";
import {sidebarObservable} from '../../../sidebar/lib/sidebarObservable';
import {AppState, WidgetData} from "./interfaces/interfaces";
import {compare} from "util/common";
import Dashboard from "./Dashboard";

declare global {
  interface Window {
    Linkspace: any,
    // @ts-expect-error "Typings clash with JSTree"
    siteConfig: any
  }
}

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

  const [widgets, setWidgets] = React.useState<WidgetData[]>(state.widgets);
  const [loadingEditHtml, setLoadingEditHtml] = React.useState(false);
  const [editError] = React.useState<string>("");
  const [editHtml, setEditHtml] = React.useState<string>("");
  const [modalOpen, setModalOpen] = React.useState(false);
  const [activeItem, setActiveItem] = React.useState<string>("");
  const [loading, setLoading] = React.useState(false);

  useEffect(() => {
    sidebarObservable.addSubscriber(() => {
      window.dispatchEvent(new Event('resize'));
    });
    initializeGlobeComponents();
  }, [])

  useEffect(() => {
    window.requestAnimationFrame(overWriteSubmitEventListener);

    if (modalOpen && !loadingEditHtml && formRef && formRef.current) {
      initializeSummernoteComponent();
    }

    if (!modalOpen && !loadingEditHtml) {
      initializeGlobeComponents();
    }
  }, [modalOpen, loadingEditHtml, formRef]);

  const overWriteSubmitEventListener = () => {
    const formContainer = document.getElementById("ld-form-container");
    if (!formContainer) return

    const form = formContainer.querySelector("form");
    if (!form) return

    form.addEventListener("submit", this.saveActiveWidget);
    const submitButton = document.createElement("input");
    submitButton.setAttribute("type", "submit");
    submitButton.setAttribute("style", "visibility: hidden");
    form.appendChild(submitButton);
  }

  const initializeGlobeComponents = () => {
    const arrGlobe = document.querySelectorAll(".globe");
    import('../../../globe/lib/component').then(({default: GlobeComponent}) => {
      arrGlobe.forEach((globe) => {
        new GlobeComponent(globe)
      });
    });
  }

  const initializeSummernoteComponent = () => {
    const summernoteEl = formRef.current.querySelector('.summernote');
    if (summernoteEl) {
      import(/* WebpackChunkName: "summernote" */ "../../../summernote/lib/component")
        .then(({default: SummerNoteComponent}) => new SummerNoteComponent(summernoteEl));
    }
  };

  useEffect(() => {
    if (modalOpen && !loadingEditHtml && formRef.current) {
      initializeSummernoteComponent();
    } else if (!modalOpen && !loadingEditHtml) {
      initializeGlobeComponents();
    }
  }, [modalOpen, loadingEditHtml]);

  const updateWidgetHtml = async (id: string) => {
    const newHtml = await api.getWidgetHtml(id);
    const newWidgets = widgets.map((widget: WidgetData) => {
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

  const fetchEditForm = async (id: string) => {
    const editFormHtml = await api.getEditForm(id);
    if (editFormHtml.is_error) {
      setLoadingEditHtml(false);
      return;
    }
    setLoadingEditHtml(false);
    setEditHtml(editFormHtml.content);
  };

  const onEditClick = (id: string) => (event: React.MouseEvent) => {
    event.preventDefault();
    showEditForm(id);
  };

  const showEditForm = (id: string) => {
    setModalOpen(true);
    setLoadingEditHtml(true);
    setActiveItem(id);
    // noinspection JSIgnoredPromiseFromCall
    fetchEditForm(id);
  };

  const closeModal = () => setModalOpen(false);

  const deleteActiveWidget = () => {
    if (!window.confirm("Deleting a widget is permanent! Are you sure?"))
      return

    setWidgets(widgets.filter(item => item.config.i !== activeItem));
    setModalOpen(false);
    // noinspection JSIgnoredPromiseFromCall
    api.deleteWidget(activeItem);
  }

  const saveActiveWidget = async (event: React.MouseEvent) => {
    event.preventDefault();
    if (!formRef) {
      console.error("No form ref was found!");
      return;
    }
    if (!formRef.current) {
      console.error("No form ref current was found!");
      return;
    }
    const formEl = formRef.current.querySelector("form");
    if (!formEl) {
      console.error("No form element was found!");
      return;
    }

    const form = serialize(formEl, {hash: true});
    const result = await api.saveWidget(formEl.getAttribute("action"), form);
    if (result.is_error) {
      console.error(result.message);
      return;
    }

    await updateWidgetHtml(activeItem);
    closeModal();
  }

  const isGridConflict = (x: number, y: number, w: number, h: number): boolean => {
    const ulc = {x, y};
    const drc = {x: x + w, y: y + h};

    return widgets.some((widget: any) => {
      if (ulc.x >= (widget.x + widget.h) || widget.x >= drc.x) {
        return false;
      }
      return !(ulc.y >= (widget.y + widget.h) || widget.y >= drc.y);
    })
  }

  const firstAvailableSpot = (w: number, h: number) => {
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
    return {x, y};
  }

  const addWidget = async (type: string) => {
    setLoading(true);
    const result = await api.createWidget(type)
    if (result.error) {
      setLoading(false);
      alert(result.message);
      return;
    }

    const id = result.message;
    const {x, y} = firstAvailableSpot(1, 1);
    const widgetLayout: WidgetData = {
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
    console.log("New Layout", newLayout);
    setWidgets(newLayout);
    setLoading(false);
    await updateWidgetHtml(id);
    await api.saveLayout(state.dashboardId, newLayout.map(widget => widget.config));
    showEditForm(id);
  }

  const onLayoutChange = (layout: RGL.Layout[]) => {
    if (shouldSaveLayout(widgets.map(widget => widget.config), layout)) {
      api.saveLayout(state.dashboardId, layout).then(() => {
        setWidgets(widgets.map((widget, index) => {
          return {
            config: layout[index],
            html: widget.html,
          }
        }))
      })
    }
  };

  const shouldSaveLayout = (prevLayout: RGL.Layout[], newLayout: RGL.Layout[]): boolean => {
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
        loading={loading}/>)}
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
        onEditClick={onEditClick}
        formRef={formRef}
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
