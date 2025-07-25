import React from 'react';
import { initializeRegisteredComponents } from 'component';

/**
 * Widget component that renders a widget with HTML content.
 */
export default class Widget extends React.Component<any, any> {
    private ref;

    /**
     * Create a Widget component.
     * @param {*} props The properties passed to the component, including the widget HTML and a flag for read-only mode.
     */
    constructor(props: any) {
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

    /**
     * Render the Widget component.
     * @returns {JSX.Element} The rendered widget component.
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
