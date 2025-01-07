import React, { useEffect, useRef } from "react";

import Header from "./Header";
import Footer from "./Footer";
import { sidebarObservable } from 'components/sidebar/lib/sidebarObservable';
import DashboardView from "./Dashboard/DashboardView";
import EditModal from "./EditModal/EditModal";

import { AppProps } from "./types"
import useApp from "./hooks/useApp";

function App(props: AppProps) {
  const formRef = useRef<HTMLDivElement>(null);

  const { currentDashboard, readOnly, hideMenu, includeH1, noDownload, widgetTypes, dashboards, gridConfig } = props;

  const { editError, editHtml, editModalOpen, layout, loading, loadingEditHtml, myWidgets, closeModal, deleteActiveWidget, saveActiveWidget, onEditClick, onLayoutChange, addWidget } = useApp(props, formRef);

  useEffect(() => {
    sidebarObservable.addSubscriber(this);

    initializeGlobeComponents();
  }, []);

  useEffect(() => {
    if (editModalOpen && !loadingEditHtml && formRef) {
      initializeSummernoteComponent();
    }

    if (!editModalOpen && !loadingEditHtml) {
      initializeGlobeComponents();
    }
  }, [editModalOpen, loadingEditHtml]);

  const initializeSummernoteComponent = () => {
    const summernoteEl = formRef.current.querySelector('.summernote');
    if (summernoteEl) {
      import(/* WebpackChunkName: "summernote" */ "../../../summernote/lib/component")
        .then(({ default: SummerNoteComponent }) => {
          new SummerNoteComponent(summernoteEl)
        });
    }
  }

  const initializeGlobeComponents = () => {
    const arrGlobe = document.querySelectorAll(".globe");
    import(/* WebpackChunkName: "globe" */ '../../../globe/lib/component').then(({ default: GlobeComponent }) => {
      arrGlobe.forEach((globe) => {
        new GlobeComponent(globe)
      });
    });
  }


  return (
    <div className="content-block">
      {hideMenu || <Header
        hMargin={gridConfig.containerPadding[0]}
        dashboards={dashboards}
        currentDashboard={currentDashboard}
        loading={loading}
        includeH1={includeH1}
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
        gridConfig={gridConfig}
        layout={layout}
        onEditClick={onEditClick}
        onLayoutChange={onLayoutChange}
        readOnly={readOnly}
        widgets={myWidgets} />
      {hideMenu || <Footer
        addWidget={addWidget}
        widgetTypes={widgetTypes}
        currentDashboard={currentDashboard}
        noDownload={noDownload}
        readOnly={readOnly}
      />}
    </div>
  );
}

export default App;
