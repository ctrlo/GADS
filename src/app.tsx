import React from "react";
import "./app.scss";
import serialize from "form-serialize";

import Modal from "react-modal";
import RGL, { WidthProvider } from "react-grid-layout";

import Header from "./header";

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
      loadingEditHtml: true,
    };
  }

  componentDidUpdate = () => {
    window.requestAnimationFrame(this.overWriteSubmitEventListener);
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
    const editFormHtml = await this.props.api.getEditFormHtml(id);
    this.setState({ loadingEditHtml: false, editHtml: editFormHtml });
  }

  onEditClick = id => (event) => {
    event.preventDefault();
    this.fetchEditForm(id);
    this.setState({ editModalOpen: true, loadingEditHtml: true, activeItem: id });
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

  saveActiveWidget = (event) => {
    event.preventDefault();
    const formEl = this.formRef.current.querySelector("form");
    if (formEl) {
      const form = serialize(formEl);
      this.props.api.saveWidget(formEl.action, form);
    } else {
      // eslint-disable-next-line no-console
      console.error("No form element was found!");
    }
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
    const id = new Date().getTime().toString(); // await this.props.api.createWidget(type)
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
    }, () => this.updateWidgetHtml(id));
    this.props.api.saveLayout(this.props.dashboardId, newLayout);
  }

  generateDOM = () => (
    this.state.widgets.map(widget => (
      <div key={widget.config.i} className="ld-widget-container">
        <button className="ld-edit-button" onClick={this.onEditClick(widget.config.i)}>Edit</button>
        <div dangerouslySetInnerHTML={{ __html: widget.html }} />
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
        <h4>Edit widget {this.state.activeItem}</h4>
        <div className='ld-modal__right-container' style={{top: 0}}>
          <button className="ld-modal__button" onClick={this.closeModal}>Close</button>
        </div>
      </div>
      <div className="ld-modal__content-container">
        {this.state.loadingEditHtml
          ? <button className='ld-modal__loading'>Loading...</button> : <div ref={this.formRef} dangerouslySetInnerHTML={{ __html: this.state.editHtml }} />}
      </div>
      <div className='ld-modal__footer'>
        <button className="ld-modal__button" onClick={this.deleteActiveWidget}>Delete</button>
        <div className='ld-modal__right-container'>
          <button className="ld-modal__button" onClick={this.closeModal}>Cancel</button>
          <button className="ld-modal__button" onClick={this.saveActiveWidget}>Save</button>
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
        />
        {this.renderModal()}
        <ReactGridLayout
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
