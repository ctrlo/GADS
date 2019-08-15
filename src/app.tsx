import React from "react";
import "./app.scss";
import serialize from "form-serialize";

import Modal from "react-modal";
import RGL, { WidthProvider } from "react-grid-layout";

import Header from "./header";

const ReactGridLayout = WidthProvider(RGL);

Modal.setAppElement("#ld-app");
const modalStyle = {
  content: {
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)",
    padding: 0,
  },
};

class App extends React.Component<any, any> {
  constructor(props) {
    super(props);

    const layout = props.widgets.map(w => w.config);
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

  updateWidgetHtml = async (i) => {
    const newHtml = await this.props.api.getWidgetHtml(i);
    const newWidgets = this.state.widgets.map((w) => {
      if (w.config.i === i) {
        return {
          ...w,
          html: newHtml,
        };
      }
      return w;
    });
    this.setState({ widgets: newWidgets });
  }

  fetchEditForm = async (i) => {
    const editFormHtml = await this.props.api.getEditFormHtml(i);
    this.setState({ loadingEditHtml: false, editHtml: editFormHtml });
  }

  onEditClick = i => (event) => {
    event.preventDefault();
    this.fetchEditForm(i);
    this.setState({ editModalOpen: true, loadingEditHtml: true, activeItem: i });
  }

  closeModal = () => {
    this.setState({ editModalOpen: false });
  }

  deleteActiveWidget = () => {
    // eslint-disable-next-line no-alert
    if (window.confirm("Deleting a widget is permanent! Are you sure?")) {
      this.setState({
        widgets: this.state.widgets.filter(item => item.config.i !== this.state.activeItem),
        editModalOpen: false,
      });
      this.props.api.deleteWidget(this.state.activeItem);
    }
  }

  saveActiveWidget = (e) => {
    e.preventDefault();
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
    const i = new Date().toISOString(); // await this.props.api.createWidget(type)
    const { x, y } = this.firstAvailableSpot(2, 2);
    const widgetLayout = {
      i,
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
    }, () => this.updateWidgetHtml(i));
    this.props.api.saveLayout(this.props.dashboardId, newLayout);
  }

  generateDOM = () => (
    this.state.widgets.map(widget => (
      <div key={widget.config.i} className="ld-widget-container">
        <span className="ld-edit-button" onClick={this.onEditClick(widget.config.i)}><u>Edit</u></span>
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
        <span className="ld-modal__button" onClick={this.closeModal}><u>Close</u></span>
      </div>
      <div className="ld-modal__content-container">
        {this.state.loadingEditHtml
          ? <span className='ld-modal__loading'>Loading...</span> : <div ref={this.formRef} dangerouslySetInnerHTML={{ __html: this.state.editHtml }} />}
      </div>
      <div className='ld-modal__footer'>
        <span className="ld-modal__button" onClick={this.deleteActiveWidget}><u>Delete</u></span>
        <div className='ld-modal__footer-right'>
          <span className="ld-modal__button" onClick={this.closeModal}><u>Cancel</u></span>
          <span className="ld-modal__button" onClick={this.saveActiveWidget}><u>Save</u></span>
        </div>
      </div>
    </Modal>
  )

  overWriteSubmitEventListener = () => {
    const formContainer = document.getElementById("ld-form-container");
    if (formContainer) {
      const form = formContainer.querySelector("form");
      if (form) {
        form.addEventListener("submit", this.saveActiveWidget);
        const submitButton = document.createElement("input");
        submitButton.setAttribute("type", "submit");
        submitButton.setAttribute("style", "visibility: hidden");
        form.appendChild(submitButton);
      }
    }
  }

  render() {
    return (
      <div>
        <Header widgetTypes={this.props.widgetTypes} addWidget={this.addWidget}/>
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
      </div>
    );
  }
}

export default App;
