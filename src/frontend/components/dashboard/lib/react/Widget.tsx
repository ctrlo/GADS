import React, { RefObject } from "react";
import { initializeRegisteredComponents } from 'component'

/**
 * Widget component
 */
export default class Widget extends React.Component<any, any> {
  private readonly ref: RefObject<HTMLDivElement>;

  /**
   * Create a new widget component
   * @param props The props for the widget component
   */
  constructor(props: any) {
    super(props);

    this.ref = React.createRef();
  }

  shouldComponentUpdate = (nextProps: any) => {
    return nextProps.widget.html !== this.props.widget.html;
  }

  componentDidUpdate = () => {
    this.initializeLinkspace();
  }

  /**
   * Initialize the component
   */
  initializeLinkspace = () => {
    if (!this.ref) {
      return;
    }
    initializeRegisteredComponents(this.ref.current)
  }

  /**
   * Render the widget component
   */
  render() {
    return (
      <React.Fragment>
        <div className="ld-widget">
          <div ref={this.ref} dangerouslySetInnerHTML={{ __html: this.props.widget.html }} />
          {this.props.readOnly ? null : <React.Fragment>
            <a className="ld-edit-button" onClick={this.props.onEditClick}><span>edit widget</span></a>
            <span className="ld-draggable-handle"><span>drag widget</span></span>
          </React.Fragment>}
        </div>
      </React.Fragment>
    );
  }
}
