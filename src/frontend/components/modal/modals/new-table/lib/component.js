import ModalComponent from 'components/modal/lib/component'
import * as DataTableHelper from 'components/data-table/lib/helper'
import { modal } from 'components/modal/lib/modal'
import SelectComponent from 'components/form-group/select/lib/component'

/**
 * Add Table Modal Component
 */
class AddTableModalComponent extends ModalComponent {
  /**
   * Create a new Modal Component
   * @param {HTMLElement} element The element to create the component in
   */
  constructor(element) {
    super(element)
    this.el = $(this.element)
    this.json = {}
    this.fieldOptions = this.el.find('.modal-body .field-options')
    this.topicsTable = this.el.find('#topics')
    this.fieldsTable = this.el.find('#fields')
    this.selectTopic = this.el.find('.modal-body .select--js-topic')[0]
    //No point doing this as an import if it's in the initialisation
    this.selectTopicComponent = new SelectComponent(this.selectTopic)
    this.currentFieldObject = {}
    this.currentTopicObject = {}

    this.initNewTable(this.el)
  }

  /**
   * Initialise the new table modal
   */
  initNewTable() {
    const btnCreateTopic = this.el.find('.modal-body .btn-js-create-topic')
    const btnCreateField = this.el.find('.modal-body .btn-js-create-field')

    btnCreateTopic.on("click", () => { modal.activate(4, true) })
    btnCreateField.on("click", () => { modal.activate(7, true) })
    this.fieldOptions.addClass('hidden')
    this.setupDataObject()
  }

  /**
   * Setup the data object
   */
  setupDataObject() {
    this.json = {
      table_permissions: [],
      topics: [],
      fields: []
    }
  }

  /**
   * Add fields to an object
   * @param {*} $fields The fields to add to an object
   * @param {*} obj The initial object to add the fields to
   * @returns The updated object
   */
  addFieldsToObject($fields, obj) {
    $fields.each((i, field) => {
      if ($(field).val()) {
        if ($(field).prop('type') == "checkbox") {
          if ($(field).prop('checked')) {
            obj[$(field).attr('name')] = true
          } else {
            obj[$(field).attr('name')] = false
          }
        } else if ($(field).attr('name') === 'topic_tempid') {
          obj[$(field).attr('name')] = parseInt($(field).val())
        } else {
          obj[$(field).attr('name')] = $(field).val()
        }
      }
    })

    return obj
  }

  /**
   * Add a topic to the json and update the topics table
   * @param {*} frame The frame to add the topic to
   */
  addTopic(frame) {
    const $fields = frame.find('input, textarea')

    // Create new topic
    if (Object.keys(this.currentTopicObject).length === 0) {
      // Add new topic
      let topicObject = {
        tempId: this.uniqueID()
      }

      // Add fields to topic
      topicObject = this.addFieldsToObject($fields, topicObject)
      this.currentTopicObject = topicObject

      // Add topic to json
      this.json.topics.push(topicObject)

      // Add topic as option to topic dropdown
      this.selectTopicComponent.addOption(topicObject['name'], topicObject['tempId'])

      // Update topics table
      const row = [
        `<button class="btn btn-link btn-js-edit-topic" type="button" data-tempid="${topicObject['tempId']}">${topicObject['name']}</button>`,
        topicObject['description'] || "",
        topicObject['expanded'],
        ""
      ]

      DataTableHelper.addRow(row, this.topicsTable)

      this.addHandlerToEditItemButton('topic')
    } else {
      // Update existing topic in json
      const currentTopic = this.json.topics.find(x => x.tempId === this.currentTopicObject.tempId)

      $fields.each((i, field) => {
        if ($(field).val()) {
          currentTopic[$(field).attr('name')] = $(field).val()
        }
      })

      // Update row in topics table
      const rowData = [
        `<button class="btn btn-link btn-js-edit-topic" type="button" data-tempid="${this.currentTopicObject['tempId']}">${this.currentTopicObject['name']}</button>`,
        this.currentTopicObject['description'] || "",
        this.currentTopicObject['expanded'],
        ""
      ]

      DataTableHelper.updateRow(rowData, this.topicsTable, this.currentTopicObject['tempId'])

      // Update topic dropdown
      this.selectTopicComponent.updateOption(this.currentTopicObject['name'], this.currentTopicObject['tempId'])

      this.addHandlerToEditItemButton('topic')
    }
  }

  /**
   * Fill in fields on a container
   * @param {*} $container The container to fill the fields in
   * @param {*} data The data to add
   */
  fillFields($container, data) {
    for (const [key, value] of Object.entries(data)) {
      const $field = $container.find(`[name=${key}]`)

      if ($field) {
        if (($field.prop('type') === 'checkbox' && value === true)) {
          $field.prop('checked', true)
        } else if (($field.prop('type') === 'hidden')) {
          $field.val(value)
          $field.trigger('change')
        } else {
          $field.val(value)
          $field.trigger('blur')
        }
      }
    }
  }

  /**
   * Edit a topic
   * @param {*} topic The topic to edit
   * @param {*} frame The frame to edit the topic in
   */
  editTopic(topic, frame) {
    this.currentTopicObject = topic

    // Fill the fields of the frame
    this.fillFields($(frame), topic)
  }

  /**
   * Edit a field
   * @param {*} field The field to edit
   * @param {*} frame The frame the field is on
   */
  editField(field, frame) {
    this.currentFieldObject = field
    // Also clear frame 8 (field type settings) and 9 (custom field permissions)
    modal.clear([8, 9])

    // Fill the fields
    this.fillFields($(frame), field)

    // Fill the field type settings
    const fieldType = field.field_type
    const fieldTypeSettingsFrame = super.getFrameByNumber(8)
    const $fieldTypeSettingsContainer = $(fieldTypeSettingsFrame).find(`[id=field_type_${fieldType}]`)

    this.fillFields($fieldTypeSettingsContainer, field.field_type_settings)

    // Fill the field permissions
    const fieldPermissions = field.custom_field_permissions
    const fieldPermissionsFrame = super.getFrameByNumber(9)

    fieldPermissions.forEach((group) => {
      const groupId = group.group_id
      const $groupRow = $(fieldPermissionsFrame).find(`tr[data-group-id=${groupId}]`)

      this.fillFields($groupRow, group.permissions)
    })
  }

  /**
   * Remove a node from the data
   * @param {*} id The id of the node
   * @param {*} data The data to remove the node from
   * @returns The list with the node removed
   */
  removeNode(id, data) {
    return data.filter((e) => {
      return e.tempId !== id
    })
  }

  /**
   * Add an event handler to the edit item button
   * @param {*} strType The type of item to add the handler to
   */
  addHandlerToEditItemButton(strType) {
    const $btnEditItem = this.el.find(`.modal-body .btn-js-edit-${strType}`)

    $btnEditItem.off('click')

    const frameNumber = strType === 'topic' ? 4 : 7

    $btnEditItem.each((i, btn) => {
      const tempId = $(btn).data('tempid')
      $(btn).on('click', () => { modal.activate(frameNumber, true, tempId) })
    })
  }

  /**
   * Generate a unique ID
   * @returns A unique ID
   */
  uniqueID() {
    return Math.floor(Math.random() * Date.now())
  }

  /**
   * Add a field to the JSON and update the fields table
   * @param {*} frame The source frame
   */
  addField(frame) {
    const $fields = frame.find('input, textarea')

    // Create new field
    if (Object.keys(this.currentFieldObject).length === 0) {
      // create new field object
      let fieldObject = {
        tempId: this.uniqueID(),
        custom_field_permissions: [],
        field_type_settings: {}
      }

      // Add fields to field object
      fieldObject = this.addFieldsToObject($fields, fieldObject)
      this.currentFieldObject = fieldObject

      // Add field object to json
      this.json.fields.push(fieldObject)

      // Update fields table
      const row = [
        `<button class="btn btn-link btn-js-edit-field" type="button" data-tempid="${fieldObject['tempId']}">${fieldObject['name']}</button>`,
        fieldObject['name'],
        fieldObject['topic'] || "",
        fieldObject['field-type'],
        ""
      ]

      DataTableHelper.addRow(row, this.fieldsTable)

      this.addHandlerToEditItemButton('field')

    } else {
      // Update existing field in json
      const currentField = this.json.fields.find(x => x.tempId === this.currentFieldObject.tempId)

      $fields.each((i, field) => {
        if ($(field).val()) {
          currentField[$(field).attr('name')] = $(field).val()
        }
      })

      // Update row in fields table
      const rowData = [
        `<button class="btn btn-link btn-js-edit-field" type="button" data-tempid="${this.currentFieldObject['tempId']}">${this.currentFieldObject['name']}</button>`,
        this.currentFieldObject['name'],
        this.currentFieldObject['topic'] || "",
        this.currentFieldObject['field-type'],
        ""
      ]

      DataTableHelper.updateRow(rowData, this.fieldsTable, this.currentFieldObject['tempId'])

      this.addHandlerToEditItemButton('field')
    }
  }

  /**
   * Add settings to the selected field according to the field type
   * @param {*} frame The frame to add the field type settings to
   */
  addFieldTypeSettings(frame) {
    const $fieldTypeContainer = frame.find('[id^=field_type_].select-reveal__instance:visible')
    const $fields = $fieldTypeContainer.find('input, textarea')
    const currentField = this.json.fields.find(x => x.tempId === this.currentFieldObject.tempId)

    switch ($fieldTypeContainer.attr('id')) {
      case 'field_type_enum':
        {
          const $orderField = $fieldTypeContainer.find('input[name="ordering"]')
          const $sortableFields = $fieldTypeContainer.find('.sortable input')

          let enumSettingsObject = {
            dropdown_values: [],
            ordering: $orderField.val()
          }

          $sortableFields.each((i, field) => {
            let fieldObj = {}
            fieldObj[$(field).attr('name')] = $(field).val()
            enumSettingsObject.dropdown_values.push(fieldObj)
          })

          currentField.field_type_settings = enumSettingsObject

          break
        }
      case 'field_type_tree':
        {
          const $jstreeEl = $fieldTypeContainer.find('.tree-widget-container')

          let treeSettingsObject = {
            data: {},
            dataJson: {}
          }

          if ($jstreeEl.length) {
            const v = $jstreeEl.jstree(true).get_json('#', { flat: false })
            //Not entirely sure what this is - I'm going to leave it in for now
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            const mytext = JSON.stringify(v)
            const data = $jstreeEl.data().jstree._model.data

            treeSettingsObject.data = data
            treeSettingsObject.dataJson = v
          }

          treeSettingsObject = this.addFieldsToObject($fields, treeSettingsObject)
          currentField.field_type_settings = treeSettingsObject

          break
        }
      case 'field_type_curval':
        {
          const $curvalFieldIds = $fieldTypeContainer.find('input[name="curval_field_ids"]:visible')
          const $otherFields = $fieldTypeContainer.find('input:not([name="curval_field_ids"]), textarea')

          let curvalSettingsObject = {
            curval_field_ids: []
          }

          $curvalFieldIds.each((i, field) => {
            if ($(field).val()) {
              curvalSettingsObject.curval_field_ids.push($(field).val())
            }
          })

          curvalSettingsObject = this.addFieldsToObject($otherFields, curvalSettingsObject)
          currentField.field_type_settings = curvalSettingsObject

          break
        }
      default:
        {
          let fieldTypeSettingsObject = {}

          fieldTypeSettingsObject = this.addFieldsToObject($fields, fieldTypeSettingsObject)
          currentField.field_type_settings = fieldTypeSettingsObject
        }
    }
  }

  /**
   * Add a table to the JSON
   * @param {*} frame The frame to add the table from
   */
  addTable(frame) {
    const $fields = frame.find('input, textarea')
    const $modalTitle = this.el.find('.modal-title')

    $fields.each((i, field) => {
      if ($(field).val()) {
        this.json[$(field).attr('name')] = $(field).val()
      }
    })

    if (this.json.name) {
      $modalTitle.html(`Table setup | ${this.json.name}`)
    }
  }

  /**
   * Add default field permissions to the json
   * @param {*} frame The frame to source the permissions from
   */
  addCustomFieldPermissions(frame) {
    const $customFieldPermissionsTable = frame.find('#custom_field_permissions_table')
    const $groups = $customFieldPermissionsTable.DataTable().rows()
    const currentField = this.json.fields.find(x => x.tempId === this.currentFieldObject.tempId)

    // Clear custom field permissions in json
    currentField.custom_field_permissions = []

    $groups.every(() => {
      const group = this.nodes()[0]
      const iGroupId = group.dataset.groupId
      const strGroupName = $(group).find('td')[0].innerHTML.trim()
      const $fields = $(group).find('input')

      // Add new group
      let groupObject = {
        group_id: iGroupId,
        group_name: strGroupName,
        permissions: {}
      }

      // Add fields to permissions object
      groupObject.permissions = this.addFieldsToObject($fields, groupObject.permissions)

      // Add groupObject to custom_field_permissions in json
      currentField.custom_field_permissions.push(groupObject)
    })
  }

  /**
   * Add table permissions to the json
   * @param {*} frame The frame to add table permissions from
   */
  addTablePermissions(frame) {
    const $groups = frame.find('.card--expandable')

    $groups.each((i, group) => {
      const $groupRow = $(group).closest('.permission-group')
      const iGroupId = ($groupRow && typeof $groupRow.data('group-id') !== 'undefined') ? $groupRow.data('group-id') : ''
      const strGroupName = $(group).find('.card__subtitle')[0].innerHTML.trim()
      const $fieldSets = $(group).find('fieldset')

      // Add new group
      let groupObject = {
        group_id: iGroupId,
        group_name: strGroupName,
        records: {},
        views: {},
        fields: {}
      }

      $fieldSets.each((i, fieldSet) => {
        const strName = $(fieldSet).data('name')
        const $fields = $(fieldSet).find('input')

        // Add fields to permissions object
        groupObject[strName] = this.addFieldsToObject($fields, groupObject[strName])
      })

      // Add groupObject to table_permissions in json
      this.json.table_permissions.push(groupObject)
    })
  }

  /**
   * Handle next
   * @param {*} frame The frame to handle next within
   */
  handleNext(frame) {
    super.handleNext()

    switch (frame.data('config').item) {
      case 'topic':
        this.addTopic(frame)
        break
      case 'field':
        this.addField(frame)
        break
      case 'field type settings':
        this.addFieldTypeSettings(frame)
        this.recalculateDatatableColumnWidths($('#custom_field_permissions_table'))
        break
      case 'custom field permissions':
        this.addCustomFieldPermissions(frame)
        break
      case 'table':
        this.addTable(frame)
        break
      case 'table permissions':
        this.addTablePermissions(frame)
        break
      default:
        {
          const $fields = frame.find('input, textarea')
          this.addFieldsToObject($fields, this.json)
        }
    }
  }

  /**
   * Adjust column widths of datatables when they become visible
   * @param {*} table The table to adjust the column widths of
   */
  recalculateDatatableColumnWidths(table) {
    table.DataTable().columns.adjust()
  }

  /**
   * Handle the back event
   */
  handleBack() {
    super.handleBack()
  }

  /**
   * Handle the save event
   * @todo Implement the save event
   */
  handleSave() {
    modal.upload(this.json)
  }

  /**
   * Handle the update event
   * @param {*} frame The frame that triggers the update event
   */
  handleUpdate(frame) {
    if (frame.data('config').item === "topic") {
      this.addTopic(frame)
      this.currentTopicObject = {}
    } else if (frame.data('config').item === "field") {
      this.addField(frame)
      this.currentFieldObject = {}
    }
  }

  /**
   * Handle the activate event
   * @param {number} frameNumber The frame number that's activated
   * @param {boolean} clearFields Whether to clear fields or not
   * @param {*} id The ID of the item to edit
   */
  handleActivate(frameNumber, clearFields, id) {
    super.handleActivate(frameNumber, clearFields)

    if ((frameNumber === 7) && id) { // Edit field
      const frame = super.getFrameByNumber(frameNumber)
      const field = this.json.fields.find(e => e.tempId === id)

      this.editField(field, frame)

    } else if ((frameNumber === 7) && clearFields) { // Add new field
      this.currentFieldObject = {}

      // Also clear frame 8 (field type settings) and 9 (custom field permissions)
      modal.clear([8, 9])

    } else if ((frameNumber === 4) && id) { // Edit topic
      const frame = super.getFrameByNumber(frameNumber)
      const topic = this.json.topics.find(e => e.tempId === id)

      this.editTopic(topic, frame)

    } else if ((frameNumber === 4) && clearFields) { // Add new topic
      this.currentTopicObject = {}
    }

    super.validateFrame()
  }

  /**
   * Handle the close event
   */
  handleClose() {
    // Collapse all collapsibles
    this.el.find('.collapse').collapse('hide')

    // Clear all datatables
    this.topicsTable && DataTableHelper.clearTable(this.topicsTable)
    this.fieldsTable && DataTableHelper.clearTable(this.fieldsTable)

    // Remove the topics from the topic dropdown
    this.selectTopicComponent.options.each((i, option) => {
      this.selectTopicComponent.removeOption(parseInt(option.dataset.value))
    })

    // Clear the JSON
    this.setupDataObject()

    // Clear the current topic and field objects
    this.currentFieldObject = {}
    this.currentTopicObject = {}

    super.handleClose()
  }
}

export default AddTableModalComponent
