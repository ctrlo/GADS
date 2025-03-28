import { Component } from 'component'
import 'jstree'
import { initValidationOnField, validateTree } from 'validation'

/**
 * Tree component
 */
class TreeComponent extends Component {
  /**
   * Create a new Tree component
   * @param {HTMLElement} element The element to attach the component to
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.isConfTree = this.el.hasClass('tree--config')

    if (this.el.find('.tree-widget-container').length > 0) {
      this.multiValue = this.el.closest('.linkspace-field').data('is-multivalue')
      this.noInitialData = this.el.data('no-initial-data')
      this.$treeContainer = this.el.find('.tree-widget-container')
      this.id = this.$treeContainer.data('column-id')
      this.field = this.$treeContainer.data('field')
      this.endNodeOnly = this.$treeContainer.data('end-node-only')
      // Used to only trigger change events once the tree has finished
      // initializing (i.e. change events that are actually initialited by a
      // user making a selection)
      this.initialized = false

      this.initTree()
    }
  }

  /**
   * Initialize the tree component
   */
  initTree() {
    const idsAsParams = this.$treeContainer.data('ids-as-params')
    const treeConfig = {
      core: {
        check_callback: true,
        force_text: true,
        themes: { stripes: false },
        worker: false,
        data: this.noInitialData ? null : this.getData(this.id, idsAsParams)
      },
      plugins: []
    }

    if (!this.multiValue) {
      treeConfig.core['multiple'] = false
    } else {
      treeConfig.plugins.push('checkbox')
    }

    if (!this.isConfTree) {
      this.$treeContainer.on('changed.jstree', (e, data) => this.handleChange(e, data))
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
          this.handleSelect(e, data)
        }
      })
      //Endfix
    }

    this.$treeContainer.on('ready.jstree', () => {
      initValidationOnField(this.el)
      this.initialized = true
    })
    this.$treeContainer.on('changed.jstree', () => validateTree(this.el))

    this.$treeContainer.jstree(treeConfig)
    this.setupJStreeButtons(this.$treeContainer)

    // hack - see https://github.com/vakata/jstree/issues/1955
    this.$treeContainer.jstree(true).settings.checkbox.cascade = 'undetermined'
  }

  /**
   * Get the data for the tree
   * @param {*} id The ID of the tree
   * @param {*} idsAsParams The IDs as params
   * @returns a data object with the URL and data to fetch the tree data
   */
  getData(id, idsAsParams) {
    const devEndpoint = window.siteConfig && window.siteConfig.urls.treeApi
    const layout_identifier = $('body').data('layout-identifier')

    return (
      {
        url: function () {
          if (devEndpoint) {
            return devEndpoint
          } else {
            return `/${layout_identifier}/tree${new Date().getTime()}/${id}?${idsAsParams}`
          }
        },
        data: function (node) {
          return { id: node.id }
        },
        dataType: 'json'
      }
    )
  }

  /**
   * Handle the select event
   * @param {JQuery.Event} e The event object (unused)
   * @param {*} data The tree data
   */
  handleSelect(e, data) {
    if (data.node.children.length == 0) {
      return
    }
    if (this.endNodeOnly) {
      this.$treeContainer.jstree(true).deselect_node(data.node)
      this.$treeContainer.jstree(true).toggle_node(data.node)
    } else if (this.multiValue) {
      this.$treeContainer.jstree(true).open_node(data.node)
    }
  }

  /**
   * Handle a change to the tree
   * @param {JQuery.Event} e The event object
   * @param {*} data The tree data
   */
  handleChange(e, data) {
    // remove all existing hidden value fields
    this.$treeContainer.nextAll('.selected-tree-value').remove()
    const selectedElms = this.$treeContainer.jstree('get_selected', true)

    $.each(selectedElms, (_, selectedElm) => {
      // store the selected values in hidden fields as children of the element.
      // Keep them in the same order as the tree (although we don't specify the
      // order of multivalue values, it makes sense to have them in the same
      // order in this case for calc values)
      const node = $(`<input type="hidden" class="selected-tree-value" name="${this.field}" value="${selectedElm.id}" />`)
        .appendTo(this.$treeContainer.closest('.tree'))
      const text_value = data.instance.get_path(selectedElm, '#')
      node.data('text-value', text_value)
    })
    // Hacky: we need to submit at least an empty value if nothing is
    // selected, to ensure the forward/back functionality works. XXX If the
    // forward/back functionality is removed, this can be removed too.
    if (selectedElms.length == 0) {
      this.$treeContainer.after(`<input type="hidden" class="selected-tree-value" name="${this.field}" value="" />`)
    }

    if (this.initialized)
      this.$treeContainer.trigger('change')
  }

  /**
   * Set up the JS tree buttons
   * @param {JQuery<HTMLElement>} $treeContainer The container for the tree
   */
  setupJStreeButtons($treeContainer) {
    const $btnExpand = this.el.find('.btn-js-tree-expand')
    const $btnCollapse = this.el.find('.btn-js-tree-collapse')
    const $btnReload = this.el.find('.btn-js-tree-reload')
    const $btnAdd = this.el.find('.btn-js-tree-add')
    const $btnRename = this.el.find('.btn-js-tree-rename')
    const $btnDelete = this.el.find('.btn-js-tree-delete')

    $btnExpand.on('click', () => { $treeContainer.jstree('open_all') })
    $btnCollapse.on('click', () => { $treeContainer.jstree('close_all') })
    $btnReload.on('click', () => { $treeContainer.jstree('refresh') })
    $btnAdd.on('click', () => { this.handleAdd() })
    $btnRename.on('click', () => { this.handleRename() })
    $btnDelete.on('click', () => { this.handleDelete() })
  }

  /**
   * Handle the add event
   */
  handleAdd() {
    const ref = this.$treeContainer.jstree(true)
    let sel = ref.get_selected()

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

  /**
   * Handle the delete event
   */
  handleDelete() {
    const ref = this.$treeContainer.jstree(true)
    let sel = ref.get_selected()

    if (!sel.length) {
      return false;
    }

    ref.delete_node(sel)
  }

  /**
   * Handle the rename event
   */
  handleRename() {
    const ref = this.$treeContainer.jstree(true)
    let sel = ref.get_selected()

    if (!sel.length) {
      return false
    }

    sel = sel[0]
    ref.edit(sel)
  }
}

export default TreeComponent
