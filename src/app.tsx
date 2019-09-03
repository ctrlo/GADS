import React from "react";
import "./app.scss";
import serialize from "form-serialize";

import Modal from "react-modal";
import RGL, { WidthProvider } from "react-grid-layout";

import Header from "./header";
import Widget from './widget';

declare global {
  interface Window {
    Linkspace : any;
  }
}

const ReactGridLayout = WidthProvider(RGL);

const modalStyle = {
  content: {
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
    zIndex: 1500
  }
};

class App extends React.Component<any, any> {
  private formRef;

  constructor(props) {
    super(props);
    Modal.setAppElement("#ld-app");

    const layout = props.widgets.map(widget => widget.config);
    this.formRef = React.createRef()

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

  componentDidUpdate = (prevProps, prevState) => {
    window.requestAnimationFrame(this.overWriteSubmitEventListener);

    if (this.state.editModalOpen && prevState.loadingEditHtml && !this.state.loadingEditHtml && this.formRef) {
      window.Linkspace.init(this.formRef.current);
    }
  }

  updateWidgetHtml = async (id) => {
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

  fetchEditForm = async (id) => {
    const editFormHtml = await this.props.api.getEditForm(id);
    if (editFormHtml.is_error) {
      this.setState({ loadingEditHtml: false, editError: editFormHtml.message });
      return;
    }
    this.setState({ loadingEditHtml: false, editError: false, editHtml: editFormHtml.content });
  }

  onEditClick = id => (event) => {
    event.preventDefault();
    this.showEditForm(id);
  }

  showEditForm = (id) => {
    this.setState({ editModalOpen: true, loadingEditHtml: true, activeItem: id });
    this.fetchEditForm(id);
  }

  closeModal = () => {
    this.setState({ editModalOpen: false });
  }

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

  saveActiveWidget = async (event) => {
    event.preventDefault();
    const formEl = this.formRef.current.querySelector("form");
    if (!formEl) {
      // eslint-disable-next-line no-console
      console.error("No form element was found!");
      return;
    }

    const form = serialize(formEl);
    const result = await this.props.api.saveWidget(formEl.getAttribute("action"), form);
    if (result.is_error) {
      this.setState({ editError: result.message });
      return;
    }
    this.updateWidgetHtml(this.state.activeItem);
    this.closeModal();
  }

  isGridConflict = (x, y, w, h) => {
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

  firstAvailableSpot = (w, h) => {
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

  // eslint-disable-next-line no-unused-vars
  addWidget = async (type) => {
    this.setState({loading: true});
    const result = await this.props.api.createWidget(type)
    if (result.error) {
      this.setState({loading: false});
      alert(result.message);
      return;
    }
    const id = result.message;
    const { x, y } = this.firstAvailableSpot(2, 2);
    const widgetLayout = {
      i: id,
      x,
      y,
      w: 2,
      h: 2,
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

  generateDOM = () => (
    this.state.widgets.map(widget => (
      <div key={widget.config.i} className={`ld-widget-container ${this.props.readOnly || widget.config.static ? "" : "ld-widget-container--editable"}`}>
        <Widget key={widget.config.i} widget={widget} readOnly={this.props.readOnly || widget.config.static} onEditClick={this.onEditClick(widget.config.i)} />
      </div>
    ))
  )

  onLayoutChange = (layout) => {
    if (this.shouldSaveLayout(this.state.layout, layout)) {
      this.props.api.saveLayout(this.props.dashboardId, layout);
    }
    this.setState({ layout });
  }

  shouldSaveLayout = (prevLayout, newLayout) => {
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

  renderModal = () => (
    <Modal
      isOpen={this.state.editModalOpen}
      onRequestClose={this.closeModal}
      style={modalStyle}
      shouldCloseOnOverlayClick={false}
      contentLabel="Edit Modal"
    >
      <div className='ld-modal__header'>
        <h4 style={{margin: 0}}>Edit widget</h4>
        <div className='ld-modal__right-container'>
          <button className="btn btn-sm btn-primary" onClick={this.closeModal}>Close</button>
        </div>
      </div>
      <div className="ld-modal__content-container">
        {this.state.editError
          ? <p className="alert alert-danger">{this.state.editError}</p> : null}
        {this.state.loadingEditHtml
          ? <span className='ld-modal__loading'>Loading...</span> : <div ref={this.formRef} dangerouslySetInnerHTML={{ __html: this.state.editHtml }} />}
      </div>
      <div className='ld-modal__footer'>
        <button className="btn btn-sm btn-primary" onClick={this.deleteActiveWidget}>Delete</button>
        <div className='ld-modal__right-container'>
          <button className="btn btn-sm btn-primary" onClick={this.saveActiveWidget}>Save</button>
        </div>
      </div>
    </Modal>
  )

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

  render() {
    return (
      <React.Fragment>
        <Header
          widgetTypes={this.props.widgetTypes}
          addWidget={this.addWidget}
          hMargin={this.props.gridConfig.containerPadding[0]}
          dashboards={this.props.dashboards}
          dashboardName={this.props.dashboardName}
          readOnly={this.props.readOnly}
          loading={this.state.loading}
        />
        {this.renderModal()}
        <ReactGridLayout
          className={`react-grid-layout ${this.props.readOnly ? "" : "react-grid-layout--editable"}`}
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
      </React.Fragment>
    );
  }
}

export default App;
