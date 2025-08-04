import React from 'react';
import { initializeRegisteredComponents } from 'component';

export default class Widget extends React.Component<any, any> {
    private ref;

    constructor(props) {
        super(props);

        this.ref = React.createRef();
    }

    shouldComponentUpdate = (nextProps) => {
        return nextProps.widget.html !== this.props.widget.html;
    };

    componentDidUpdate = () => {
        this.initializeLinkspace();
    };

    initializeLinkspace = () => {
        if (!this.ref) {
            return;
        }
        initializeRegisteredComponents(this.ref.current);
    };

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
