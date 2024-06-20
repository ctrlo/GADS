import { Component } from 'component';
import  'jstree';
import { initValidationOnField, validateTree } from 'validation';

class TreeComponent extends Component {
  constructor(element)  {
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

    this.$treeContainer.on('select_node.jstree', (e, data) => this.handleSelect(e, data));
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

  getData(id, idsAsParams) {
    const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi;
    const layout_identifier = $('body').data('layout-identifier');

    return (
      {
        url: function() {
          if (devEndpoint) {
            return devEndpoint;
          } else {
            return `/${layout_identifier}/tree${new Date().getTime()}/${id}?${idsAsParams}`;
          }
        },
        data: function(node) {
          return { id: node.id };
        },
        dataType: 'json'
      }
    );
  }

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

  setupJStreeButtons($treeContainer) {
    const $btnExpand = this.el.find('.btn-js-tree-expand');
    const $btnCollapse = this.el.find('.btn-js-tree-collapse');
    const $btnReload = this.el.find('.btn-js-tree-reload');
    const $btnAdd = this.el.find('.btn-js-tree-add');
    const $btnRename = this.el.find('.btn-js-tree-rename');
    const $btnDelete = this.el.find('.btn-js-tree-delete');

    $btnExpand.on('click', () => {$treeContainer.jstree('open_all');});
    $btnCollapse.on('click', () => {$treeContainer.jstree('close_all');});
    $btnReload.on('click', () => {$treeContainer.jstree('refresh');});
    $btnAdd.on('click', () => {this.handleAdd();});
    $btnRename.on('click', () => {this.handleRename();});
    $btnDelete.on('click', () => {this.handleDelete();});
  }

  handleAdd() {
    const ref = this.$treeContainer.jstree(true);
    let sel = ref.get_selected();

    if (sel.length) {
      sel = sel[0];
    } else {
      sel = "#";
    }

    sel = ref.create_node(sel, { type: "file" });

    if (sel) {
      ref.edit(sel);
    }
  }

  handleDelete() {
    const ref = this.$treeContainer.jstree(true);
    let sel = ref.get_selected();

    if (!sel.length) {
      return false;
    }

    ref.delete_node(sel);
  }

  handleRename() {
    const ref = this.$treeContainer.jstree(true);
    let sel = ref.get_selected();

    if (!sel.length) {
      return false;
    }

    sel = sel[0];
    ref.edit(sel);
  }
}

export default TreeComponent;
