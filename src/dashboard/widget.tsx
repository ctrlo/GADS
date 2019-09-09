import React from "react";

export default class Widget extends React.Component<any, any> {
  private ref;

  constructor(props) {
    super(props);

    this.ref = React.createRef();
  }

  shouldComponentUpdate = (nextProps) => {
    return nextProps.widget.html !== this.props.widget.html;
  }

  componentDidUpdate = () => {
    this.initializeLinkspace();
  }

  initializeLinkspace = () => {
    if (!this.ref) {
      return;
    }
    window.Linkspace.init(this.ref.current);
  }

  render() {
    return (
      <React.Fragment>
        <div ref={this.ref} dangerouslySetInnerHTML={{ __html: this.props.widget.html }} />
        {this.props.readOnly ? null : <React.Fragment>
          <a className="ld-edit-button" onClick={this.props.onEditClick}><i className="fa fa-edit"></i></a>
          <span className="ld-draggable-handle"><i className="fa fa-arrows"></i></span>
        </React.Fragment>}
      </React.Fragment>
    );
  }
}
