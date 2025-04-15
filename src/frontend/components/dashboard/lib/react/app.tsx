import React, { RefObject } from "react";
import serialize from "form-serialize";

import Modal from "react-modal";
import RGL, { WidthProvider } from "react-grid-layout";

import Header from "./Header";
import Widget from './Widget';
import Footer from "./Footer";
import { sidebarObservable } from '../../../sidebar/lib/sidebarObservable';

declare global {
  interface Window {
    Linkspace: any,
    // @ts-expect-error "Typings clash with JSTree"
    siteConfig: any
  }
}

const ReactGridLayout = WidthProvider(RGL);

const modalStyle = {
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

/**
 * Main App Component
 */
class App extends React.Component<any, any> {
  private formRef: RefObject<HTMLDivElement>;

  /**
   * Create the App component
   * @param props The props passed to the component
   */
  constructor(props: any) {
    super(props);
    Modal.setAppElement("#ld-app");

    const layout = props.widgets.map((widget: any) => widget.config);
    this.formRef = React.createRef();
    sidebarObservable.addSubscriber(this);

    this.state = {
      widgets: props.widgets,
      layout,
      editModalOpen: false,
      activeItem: 0,
      editHtml: "",
      editError: null,
      loading: false,
      loadingEditHtml: true,
    };
  }

  componentDidMount = () => {
    this.initializeGlobeComponents();
  }

  componentDidUpdate = (prevProps, prevState) => {
    window.requestAnimationFrame(this.overWriteSubmitEventListener);

    if (this.state.editModalOpen && prevState.loadingEditHtml && !this.state.loadingEditHtml && this.formRef) {
      this.initializeSummernoteComponent();
    }

    if (!this.state.editModalOpen && !prevState.loadingEditHtml && !this.state.loadingEditHtml) {
      this.initializeGlobeComponents();
    }
  }

  /**
   * Initialize the Summernote component
   */
  initializeSummernoteComponent = () => {
    const summernoteEl = this.formRef.current.querySelector('.summernote');
    if (summernoteEl) {
      import(/* WebpackChunkName: "summernote" */ "../../../summernote/lib/component")
        .then(({ default: SummerNoteComponent }) => {
          new SummerNoteComponent(summernoteEl as HTMLElement)
        });
    }
  }

  /**
   * Initialize the Globe component
   */
  initializeGlobeComponents = () => {
    const arrGlobe = document.querySelectorAll(".globe");
    import('../../../globe/lib/component').then(({ default: GlobeComponent }) => {
      arrGlobe.forEach((globe) => {
        new GlobeComponent(globe as HTMLElement)
      });
    });
  }

  /**
   * Update the widget HTML
   * @param id The ID of the widget to update
   */
  updateWidgetHtml = async (id: string) => {
    const newHtml = await this.props.api.getWidgetHtml(id);
    const newWidgets = this.state.widgets.map(widget => {
      if (widget.config.i === id) {
        return {
          ...widget,
          html: newHtml,
        };
      }
      return widget;
    });
    this.setState({ widgets: newWidgets });
  }

  /**
   * Fetch the edit form for a widget
   * @param id The ID of the widget to fetch the edit form for
   */
  fetchEditForm = async (id: string) => {
    const editFormHtml = await this.props.api.getEditForm(id);
    if (editFormHtml.is_error) {
      this.setState({ loadingEditHtml: false, editError: editFormHtml.message });
      return;
    }
    this.setState({ loadingEditHtml: false, editError: false, editHtml: editFormHtml.content });
  }

  /**
   * On edit click event handler
   * @param id The ID of the widget to edit
   * @param event The event that triggered the edit
   */
  onEditClick = (id: string) => (event: MouseEvent) => {
    event.preventDefault();
    this.showEditForm(id);
  }

  /**
   * Show the edit form for a widget
   * @param id The ID of the widget to show the edit form for
   */
  showEditForm = (id: string) => {
    this.setState({ editModalOpen: true, loadingEditHtml: true, activeItem: id });
    this.fetchEditForm(id);
  }

  /**
   * Close the edit modal
   */
  closeModal = () => {
    this.setState({ editModalOpen: false });
  }

  /**
   * Delete the active widget
   */
  deleteActiveWidget = () => {
    // eslint-disable-next-line no-alert
    if (!window.confirm("Deleting a widget is permanent! Are you sure?"))
      return

    this.setState({
      widgets: this.state.widgets.filter(item => item.config.i !== this.state.activeItem),
      editModalOpen: false,
    });
    this.props.api.deleteWidget(this.state.activeItem);
  }

  /**
   * Save the active widget
   * @param event The event that triggered the save
   */
  saveActiveWidget = async (event: any) => {
    event.preventDefault();
    const formEl = this.formRef.current.querySelector("form");
    if (!formEl) {
      // eslint-disable-next-line no-console
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
  }

  /**
   * Check for a grid conflict when placing or adding a widget
   * @param x The x coordinate of the widget
   * @param y The y coordinate of the widget
   * @param w The width of the widget
   * @param h The height of the widget
   * @returns True if there is a conflict with the grid, false otherwise
   */
  isGridConflict = (x: number, y: number, w: number, h: number):boolean => {
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
  }

  /**
   * Find the first available spot for a widget in the grid
   * @param w The width of the widget
   * @param h The height of the widget
   * @returns The first available spot for the widget
   */
  firstAvailableSpot = (w: number, h: number) => {
    let x = 0;
    let y = 0;
    while (this.isGridConflict(x, y, w, h)) {
      if ((x + w) < this.props.gridConfig.cols) {
        x += 1;
      } else {
        x = 0;
        y += 1;
      }
      if (y > 200) break;
    }
    return { x, y };
  }

  /**
   * Add a widget to the dashboard
   * @param type The type of widget to add
   */
  // eslint-disable-next-line no-unused-vars
  addWidget = async (type: string) => {
    this.setState({ loading: true });
    const result = await this.props.api.createWidget(type)
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
      h: 1,
    };
    const newLayout = this.state.layout.concat(widgetLayout);
    this.setState({
      widgets: this.state.widgets.concat({
        config: widgetLayout,
        html: "Loading...",
      }),
      layout: newLayout,
      loading: false,
    }, () => this.updateWidgetHtml(id));
    this.props.api.saveLayout(this.props.dashboardId, newLayout);
    this.showEditForm(id);
  }

  /**
   * Generate the widget DOM elements
   * @returns The DOM elements for the widgets
   */
  generateDOM = () => (
    this.state.widgets.map(widget => (
      <div key={widget.config.i} className={`ld-widget-container ${this.props.readOnly || widget.config.static ? "" : "ld-widget-container--editable"}`}>
        <Widget key={widget.config.i} widget={widget} readOnly={this.props.readOnly || widget.config.static} onEditClick={this.onEditClick(widget.config.i)} />
      </div>
    ))
  )

  /**
   * Event handler for when the grid layout changes
   * @param layout The new layout of the grid
   */
  onLayoutChange = (layout: any) => {
    if (this.shouldSaveLayout(this.state.layout, layout)) {
      this.props.api.saveLayout(this.props.dashboardId, layout);
    }
    this.setState({ layout });
  }

  /**
   * Check if the new layout needs saving
   * @param prevLayout The previous layout of the grid
   * @param newLayout The new layout of the grid
   * @returns True if the layout should be saved, false otherwise
   */
  shouldSaveLayout = (prevLayout: any, newLayout: any) => {
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

  /**
   * Render the edit modal
   */
  renderModal = () => (
    <Modal
      isOpen={this.state.editModalOpen}
      onRequestClose={this.closeModal}
      style={modalStyle}
      shouldCloseOnOverlayClick={true}
      contentLabel="Edit Modal"
    >
      <div className='modal-header'>
        <div className='modal-header__content'>
          <h3 className='modal-title'>Edit widget</h3>
        </div>
        <button className='close' onClick={this.closeModal}><span aria-hidden='true' className='hidden'>Close</span></button>
      </div>
      <div className="modal-body">
        {this.state.editError
          ? <p className="alert alert-danger">{this.state.editError}</p> : null}
        {this.state.loadingEditHtml
          ? <span className='ld-modal__loading'>Loading...</span> : <div ref={this.formRef} dangerouslySetInnerHTML={{ __html: this.state.editHtml }} />}
      </div>
      <div className='modal-footer'>
        <div className='modal-footer__left'>
          <button className="btn btn-cancel" onClick={this.deleteActiveWidget}>Delete</button>
        </div>
        <div className='modal-footer__right'>
          <button className="btn btn-default" onClick={this.saveActiveWidget}>Save</button>
        </div>
      </div>
    </Modal>
  )

  /**
   * Overwrite the submit event
   */
  overWriteSubmitEventListener = () => {
    const formContainer = document.getElementById("ld-form-container");
    if (!formContainer)
      return

    const form = formContainer.querySelector("form");
    if (!form)
      return

    form.addEventListener("submit", this.saveActiveWidget);
    const submitButton = document.createElement("input");
    submitButton.setAttribute("type", "submit");
    submitButton.setAttribute("style", "visibility: hidden");
    form.appendChild(submitButton);
  }

  /**
   * Handler for when the sidebar is expanded or collapsed
   */
  handleSideBarChange = () => {
    window.dispatchEvent(new Event('resize'));
  }

  /**
   * Render the component
   */
  render() {
    return (
      <div className="content-block">
        {this.props.hideMenu ? null : <Header
          hMargin={this.props.gridConfig.containerPadding[0]}
          dashboards={this.props.dashboards}
          currentDashboard={this.props.currentDashboard}
          loading={this.state.loading}
          includeH1={this.props.includeH1}
        />}
        {this.renderModal()}
        <div className="content-block__main">
          <ReactGridLayout
            className={`content-block__main-content ${this.props.readOnly ? "" : "react-grid-layout--editable"}`}
            isDraggable={!this.props.readOnly}
            isResizable={!this.props.readOnly}
            draggableHandle=".ld-draggable-handle"
            useCSSTransforms={false}
            layout={this.state.layout}
            onLayoutChange={this.onLayoutChange}
            items={this.state.layout.length}
            {...this.props.gridConfig}
          >
            {this.generateDOM()}
          </ReactGridLayout>
        </div>
        {this.props.hideMenu ? null : <Footer
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

export default App;
