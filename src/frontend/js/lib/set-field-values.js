import CurvalModalComponent from 'components/modal/modals/curval'
import documentComponent from 'components/form-group/input/lib/documentComponent'
import "jstree";

/*
  Set the value of a field, depending on its type.

  curval fields not supported at the time of writing

  For text only values, accepts arrays of strings

  For enum-type values (enums, trees, people) accepts an object with either an
  "id" key or a "text" key, with the required value
*/

const setFieldValues = function ($field, values) {

  const type = $field.data("column-type")
  const name = $field.data("name")

  if (!Array.isArray(values)) {
    throw new Error(`Attempt to set value for ${name} without array`)
  }

  if (type === "enum") {

    if ($field.data("is-multivalue")) {
      set_enum_multi($field, values)
    } else {
      set_enum_single($field, values)
    }

  } else if (type === "person") {

    if ($field.data("is-multivalue")) {
      set_enum_multi($field, values)
    } else {
      set_enum_single($field, values)
    }

  } else if (type === "tree") {

    set_tree($field, values)

  } else if (type === "daterange") {

    values.forEach(function (value, index) {
      let $single = prepare_multi($field, index)
      set_daterange($single, value)
    })

  } else if (type === "date") {

    values.forEach(function (value, index) {
      let $single = prepare_multi($field, index)
      set_date($single, value)
    })

  } else if (type === "string" || type === "intgr") {

    if (values.length === 0) set_string($field, "")
    values.forEach(function (value, index) {
      let $single = prepare_multi($field, index)
      set_string($single, value)
    })

  } else if (type === "file") {

    $field.find(".fileupload__files").empty();
    // Component needs to be set up above .input--document div but below the
    // fieldset div. The latter also has a .input class but it should be the
    // former that becomes the component
    let filecomp = (documentComponent($field.find('.file-upload')));
    values.forEach(function (value) {
      filecomp.addFileToField({ id: value.id, name: value.filename });
    })

  } else if (type === "curval") {

    // Curval values can be either integers (existing record IDs) or completely
    // new draft records
    let ids = values.filter((item) => Number.isInteger(item));
    // For IDs, set them as normal enums
    if ($field.data("is-multivalue")) {
      set_enum_multi($field, ids);
    } else {
      set_enum_single($field, ids);
    }
    // For draft records, resubmit them through the modal
    let records = values.filter((item) => !Number.isInteger(item));
    let curval = (CurvalModalComponent($field.closest('.content-block')))[0];
    curval.setValue($field, records);
  } else {
    throw new Error(`Unable to set value for field ${name}: ${type}`);
  }
}

// Deal with either single value field or field with multiple inputs. Create as
// many inputs as required
const prepare_multi = function ($field, index) {
  if ($field.data("is-multivalue")) {
    let $multi_container = $field.find(".multiple-select__list")
    let existing_count = $multi_container.children().length
    if (index >= existing_count) {
      $field.find(".btn-add-link").trigger("click")
    }
    return $multi_container.children().eq(index)
  } else {
    return $field
  }
}

const set_enum_single = function ($element, values) {

  const type = $element.data("column-type")
  // Accept ID or text value, specified depending on the key of the value
  // object
  values.forEach(function (value) {
    let $option
    let val
    if (/^\d+$/.test(value)) { // Value could be a stringified integer
      $option = $element.find(`input[value='${value}']`)
    } else if (Object.prototype.hasOwnProperty.call(value, 'id')) {
      val = value['id']
      $option = $element.find(`input[value='${val}']`)
    } else if (Object.prototype.hasOwnProperty.call(value, 'text')) {
      val = value['text']
      $option = $element.find(`input[data-value='${val}']`)
    } else {
      throw new Error("Unknown value or key for single enum")
    }
    if ($option.length) {
      $option.trigger("click")
    } else {
      let name = $element.data("name")
      if (type === 'curval') {
        throw new Error(`Unable to set value for ${name} - the data may have been changed or removed`)
      } else {
        throw new Error(`Unknown value ${val} for ${name}`)
      }
    }
  })

}

const set_enum_multi = function ($element, values) {

  const id_hash = {}
  const text_hash = {}

  values.forEach((elem) => {
    if (/^\d+$/.test(elem)) { // Value could be a stringified integer
      id_hash[elem] = false
    } else if (Object.prototype.hasOwnProperty.call(elem, 'id')) {
      id_hash[elem.id] = false
    } else if (Object.prototype.hasOwnProperty.call(elem, 'text')) {
      text_hash[elem.text] = false
    } else {
      throw new Error("Unknown value or key for multi enum")
    }
  })

  // Iterate each available checkbox, and select or deselect as required to
  // match values
  $element.find('.checkbox').each(function () {
    let $check = $(this).find('input')
    // Mark an option checked if either the id or text value match the
    // submitted values
    if (Object.prototype.hasOwnProperty.call(id_hash, $check.val()) || Object.prototype.hasOwnProperty.call(text_hash, $check.data("value"))) {
      if (!$check.is(":checked")) {
        $check.trigger("click")
      }
      if (Object.prototype.hasOwnProperty.call(id_hash, $check.val())) id_hash[$check.val()] = true
      if (Object.prototype.hasOwnProperty.call(text_hash, $check.data("value"))) text_hash[$check.data("value")] = true
    } else {
      if ($check.is(":checked")) {
        $check.trigger("click")
      }
    }
  })

  // Report any values that weren't used
  let name = $element.data("name")
  let type = $element.data("column-type")
  for (const [value, used] of Object.entries(id_hash)) {
    if (!used && type !== "curval") {
      throw new Error(`Unable to set value for ${name} - the data may have been changed or removed`)
    } else if (!used) {
      throw new Error(`Unmatched value ${value} for ${name}`)
    }
  }
  for (const [value, used] of Object.entries(text_hash)) {
    if (!used) {
      if (!used && type !== "curval") {
        throw new Error(`Unable to set value for ${name} - the data may have been changed or removed`)
      } else if (!used) {
        throw new Error(`Unmatched value ${value} for ${name}`)
      }
    }
  }
}

const set_date = function ($element, value) {
  const $input = $element.find('input')
  if (/^\d+$/.test(value)) {
    // Assume epoch
    $input.datepicker('update', new Date(value * 1000))
  } else {
    // Otherwise assume string
    if (typeof value === 'object') {
      if (value.epoch) {
        $input.datepicker('update', new Date(value.epoch * 1000))
      } else {
        $input.datepicker('setDate', `${value.year}-${value.month}-${value.day}`)
      }
    } else {
      $input.datepicker('setDate', value)
    }
  }
}

const set_daterange = function ($element, value) {
  set_date($element.find('.input--from'), value.from)
  set_date($element.find('.input--to'), value.to)
}

const set_string = function ($element, value) {
  const $input = $element.find('input').length ? $element.find('input') : $element.find('textarea');
  $input.val(value).trigger("change")
}

const set_tree = function ($field, values) {

  let $jstree = $field.find('.jstree').jstree(true)
  let nodes = $jstree.get_json('#', { flat: true })

  // Create a hash to map all the text values to ids, in case value is supplied
  // by text
  const nodes_hash = {}
  nodes.forEach((node) => {
    nodes_hash[node.text] = node.id
  })
  $jstree.deselect_all()
  values.forEach(function (value) {
    let id
    if (/^\d+$/.test(value)) { // Value could be a stringified integer
      id = value
    } else if (Object.prototype.hasOwnProperty.call(value, 'id')) {
      id = value['id']
    } else if (Object.prototype.hasOwnProperty.call(value, 'text')) {
      if (Object.prototype.hasOwnProperty.call(nodes_hash, value['text'])) {
        id = nodes_hash[value['text']]
      } else {
        console.debug("Unknown text value for tree: " + value['text'])
      }
    } else {
      throw new Error("Unknown value key for tree")
    }
    $jstree.select_node(id)
  })
}

export { setFieldValues }
