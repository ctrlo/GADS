import { Component } from 'component';
import 'jstree';
import { initValidationOnField, validateTree } from 'validation';

/**
 * Component to display a tree structure using jstree.
 */
class TreeComponent extends Component {
    /**
     * Create a new TreeComponent.
     * @param {HTMLElement} element The HTML element that this component is attached to.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.isConfTree = this.el.hasClass('tree--config');

        if (this.el.find('.tree-widget-container').length > 0) {
            this.multiValue = this.el.closest('.linkspace-field').data('is-multivalue');
            this.noInitialData = this.el.data('no-initial-data');
            this.$treeContainer = this.el.find('.tree-widget-container');
            this.id = this.$treeContainer.data('column-id');
            this.field = this.$treeContainer.data('field');
            this.endNodeOnly = this.$treeContainer.data('end-node-only');
            // Used to only trigger change events once the tree has finished
            // initializing (i.e. change events that are actually initialited by a
            // user making a selection)
            this.initialized = false;

            this.initTree();
        }
    }

    /**
     * Initializes the jstree with the appropriate configuration.
     */
    initTree() {
        const idsAsParams = this.$treeContainer.data('ids-as-params');
        const treeConfig = {
            core: {
                check_callback: true,
                force_text: true,
                themes: { stripes: false },
                worker: false,
                data: this.noInitialData ? null : this.getData(this.id, idsAsParams)
            },
            plugins: []
        };

        if (!this.multiValue) {
            treeConfig.core['multiple'] = false;
        } else {
            treeConfig.plugins.push('checkbox');
        }

        if (!this.isConfTree) {
            this.$treeContainer.on('changed.jstree', (e, data) => this.handleChange(e, data));
        }

        // The below fix is to prevent the tree from erroring when it is a multivalue and a value is deselected
        if (!this.multiValue) {
            //Deselect Fix - 26.04.24 - DR
            //Unless you have a click event, the select_node event doesn't trigger when you click on the same node - I don't know why this is,
            //all I know is, it gave me a headache! Either way, it appears to work now, so I'm happy!!
            let node;

            this.$treeContainer.on('click', '.jstree-clicked', () => {
                if (!node) throw 'Not a node!';
                this.$treeContainer.jstree(true).deselect_node(node);
            });

            this.$treeContainer.on('select_node.jstree', (e, data) => {
                if (node && data.node.id == node.id) {
                    this.$treeContainer.jstree(true).deselect_node(data.node);
                    node = null;
                } else {
                    node = data.node;
                    this.handleSelect(e, data);
                }
            });
            //Endfix
        }

        this.$treeContainer.on('ready.jstree', () => {
            initValidationOnField(this.el);
            this.initialized = true;
        });
        this.$treeContainer.on('changed.jstree', () => validateTree(this.el));

        this.$treeContainer.jstree(treeConfig);
        this.setupJStreeButtons(this.$treeContainer);

        // hack - see https://github.com/vakata/jstree/issues/1955
        this.$treeContainer.jstree(true).settings.checkbox.cascade = 'undetermined';
    }

    /**
     * Get the data for the jstree.
     * @param {number} id The ID of the tree to fetch data for.
     * @param {string} idsAsParams The parameters in the request.
     * @returns {object} The configuration object for the jstree data source.
     */
    getData(id, idsAsParams) {
        const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi;
        const layout_identifier = $('body').data('layout-identifier');

        return (
            {
                url: function () {
                    if (devEndpoint) {
                        return devEndpoint;
                    } else {
                        return `/${layout_identifier}/tree${new Date().getTime()}/${id}?${idsAsParams}`;
                    }
                },
                data: function (node) {
                    return { id: node.id };
                },
                dataType: 'json'
            }
        );
    }

    /**
     * Handle the selection of a node in the jstree.
     * @param {JQuery.TriggeredEvent} e The event triggered by the jstree.
     * @param {object} data The data object containing the node information.
     * @todo This method can have the event parameter removed, as it is not used.
     */
    handleSelect(e, data) {
        if (data.node.children.length == 0) {
            return;
        }
        if (this.endNodeOnly) {
            this.$treeContainer.jstree(true).deselect_node(data.node);
            this.$treeContainer.jstree(true).toggle_node(data.node);
        } else if (this.multiValue) {
            this.$treeContainer.jstree(true).open_node(data.node);
        }
    }

    /**
     * Handle change to the jstree selection.
     * @param {JQuery.TriggeredEvent} e The event triggered by the jstree.
     * @param {object} data The data object containing the selected nodes.
     * @todo This method can have the event parameter removed, as it is not used.
     */
    handleChange(e, data) {
    // remove all existing hidden value fields
        this.$treeContainer.nextAll('.selected-tree-value').remove();
        const selectedElms = this.$treeContainer.jstree('get_selected', true);

        $.each(selectedElms, (_, selectedElm) => {
            // store the selected values in hidden fields as children of the element.
            // Keep them in the same order as the tree (although we don't specify the
            // order of multivalue values, it makes sense to have them in the same
            // order in this case for calc values)
            const node = $(`<input type="hidden" class="selected-tree-value" name="${this.field}" value="${selectedElm.id}" />`)
                .appendTo(this.$treeContainer.closest('.tree'));
            const text_value = data.instance.get_path(selectedElm, '#');
            node.data('text-value', text_value);
        });
        // Hacky: we need to submit at least an empty value if nothing is
        // selected, to ensure the forward/back functionality works. XXX If the
        // forward/back functionality is removed, this can be removed too.
        if (selectedElms.length == 0) {
            this.$treeContainer.after(`<input type="hidden" class="selected-tree-value" name="${this.field}" value="" />`);
        }

        if (this.initialized)
            this.$treeContainer.trigger('change');
    }

    /**
     * Setup the jstree buttons for expand, collapse, reload, add, rename, and delete.
     * @param {JQuery<HTMLElement>} $treeContainer The jstree container element.
     */
    setupJStreeButtons($treeContainer) {
        const $btnExpand = this.el.find('.btn-js-tree-expand');
        const $btnCollapse = this.el.find('.btn-js-tree-collapse');
        const $btnReload = this.el.find('.btn-js-tree-reload');
        const $btnAdd = this.el.find('.btn-js-tree-add');
        const $btnRename = this.el.find('.btn-js-tree-rename');
        const $btnDelete = this.el.find('.btn-js-tree-delete');

        $btnExpand.on('click', () => { $treeContainer.jstree('open_all'); });
        $btnCollapse.on('click', () => { $treeContainer.jstree('close_all'); });
        $btnReload.on('click', () => { $treeContainer.jstree('refresh'); });
        $btnAdd.on('click', () => { this.handleAdd(); });
        $btnRename.on('click', () => { this.handleRename(); });
        $btnDelete.on('click', () => { this.handleDelete(); });
    }

    /**
     * Handle the addition of a new node to the jstree.
     */
    handleAdd() {
        const ref = this.$treeContainer.jstree(true);
        let sel = ref.get_selected();

        if (sel.length) {
            sel = sel[0];
        } else {
            sel = '#';
        }

        sel = ref.create_node(sel, { type: 'file' });

        if (sel) {
            ref.edit(sel);
        }
    }

    /**
     * Handle the deletion of a node from the jstree.
     * @returns {boolean} Returns true if a node was deleted, false otherwise.
     * @todo Why does this have a return value?
     */
    handleDelete() {
        const ref = this.$treeContainer.jstree(true);
        let sel = ref.get_selected();

        if (!sel.length) {
            return false;
        }

        ref.delete_node(sel);
        return true;
    }

    /**
     * Handle the renaming of a node in the jstree.
     * @returns {boolean} Returns true if a node was renamed, false otherwise.
     * @todo Why does this have a return value?
     */
    handleRename() {
        const ref = this.$treeContainer.jstree(true);
        let sel = ref.get_selected();

        if (!sel.length) {
            return false;
        }

        sel = sel[0];
        ref.edit(sel);
        return true;
    }
}

export default TreeComponent;
