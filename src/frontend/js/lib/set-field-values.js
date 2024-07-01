/*
  Set the value of a field, depending on its type.

  curval fields not supported at the time of writing

  For text only values, accepts arrays of strings

  For enum-type values (enums, trees, people) accepts an object with either an
  "id" key or a "text" key, with the required value
*/

const setFieldValues = function($field, values) {

  const type = $field.data("column-type");
  const name = $field.data("name");

  if (!Array.isArray(values)) {
    console.error(`Attempt to set value for ${name} without array`);
    return;
  }

  if (type === "enum") {

    if ($field.data("is-multivalue")) {
      set_enum_multi($field, values);
    } else {
      set_enum_single($field, values);
    }

  } else if (type === "person") {

    if ($field.data("is-multivalue")) {
      set_enum_multi($field, values);
    } else {
      set_enum_single($field, values);
    }

  } else if (type === "tree") {

    set_tree($field, values);

  } else if (type === "daterange") {

    values.forEach(function(value, index){
      let $single = prepare_multi($field, index);
      set_daterange($single, value);
    });

  } else if (type === "date") {

    values.forEach(function(value, index){
      let $single = prepare_multi($field, index);
      set_date($single, value);
    });

  } else if (type === "string" || type === "intgr") {

    values.forEach(function(value, index){
      let $single = prepare_multi($field, index);
      set_string($single, value);
    });

  } else {

    console.error(`Unable to set value for field ${name}: ${type}`);

  }
};

// Deal with either single value field or field with multiple inputs. Create as
// many inputs as required
const prepare_multi = function($field, index) {
  if ($field.data("is-multivalue")) {
    let $multi_container = $field.find(".multiple-select__list");
    let existing_count = $multi_container.children().length;
    if (index >= existing_count) {
      $field.find(".btn-add-link").trigger("click");
    }
    return $multi_container.children().eq(index);
  } else {
    return $field;
  }
};

const set_enum_single = function($element, values) {

  // Accept ID or text value, specified depending on the key of the value
  // object
  values.forEach(function(value){
    let $option;
    let val;
    if (value.hasOwnProperty("id")) {
      val = value["id"];
      $option = $element.find(`input[value='${val}']`);
    } else if (value.hasOwnProperty("text")) {
      val = value["text"];
      $option = $element.find(`input[data-value='${val}']`);
    } else {
      console.error("Unknown key for single enum");
    }
    if ($option.length) {
      $option.trigger("click");
    } else {
      let name = $element.data("name");
      console.log(`Unknown value ${val} for ${name}`);
    }
  });

};

const set_enum_multi = function($element, values) {

  const id_hash = {};
  const text_hash = {};

  values.forEach((elem) => {
    if (elem.hasOwnProperty("id")) {
      id_hash[elem.id] = false;
    } else if (elem.hasOwnProperty("text")) {
      text_hash[elem.text] = false;
    } else {
      console.error("Unknown key for multi enum");
    }
  });

  // Iterate each available checkbox, and select or deselect as required to
  // match values
  $element.find(".checkbox").each(function(){
    let $check = $(this).find("input");
    // Mark an option checked if either the id or text value match the
    // submitted values
    if (id_hash.hasOwnProperty($check.val()) || text_hash.hasOwnProperty($check.data("value"))) {
      if (!$check.is(":checked")) {
        $check.trigger("click");
      }
      if (id_hash.hasOwnProperty($check.val())) id_hash[$check.val] = true;
      if (text_hash.hasOwnProperty($check.data("value"))) text_hash[$check.data("value")] = true;
    } else {
      if ($check.is(":checked")) {
        $check.trigger("click");
      }
    }
  });

  // Report any values that weren't used
  let name = $element.data("name");
  for (const [value, used] of Object.entries(id_hash)) {
    if (!used) {
      console.log(`Unmatched value ${value} for ${name}`);
    }
  }
  for (const [value, used] of Object.entries(text_hash)) {
    if (!used) {
      console.log(`Unmatched value ${value} for ${name}`);
    }
  }
};

const set_date = function($element, value) {
  $element.find("input").datepicker("update", new Date(value * 1000));
};

const set_daterange = function($element, value) {
  set_date($element.find(".input--from"), value.from);
  set_date($element.find(".input--to"), value.to);
};

const set_string = function($element, value) {
  $element.find("input").val(value);
};

const set_tree = function($field, values) {

  let $jstree = $field.find(".jstree").jstree(true);
  let nodes = $jstree.get_json("#", { flat: true });

  // Create a hash to map all the text values to ids, in case value is supplied
  // by text
  const nodes_hash = {};
  nodes.forEach((node) => {
    nodes_hash[node.text] = node.id;
  });
  $jstree.deselect_all();
  values.forEach(function(value){
    let id;
    if (value.hasOwnProperty("id")) {
      id = value["id"];
    } else if (value.hasOwnProperty("text")) {
      if (nodes_hash.hasOwnProperty(value["text"])) {
        id = nodes_hash[value["text"]];
      } else {
        console.debug("Unknown text value for tree: " + value["text"]);
      }
    } else {
        console.error("Unknown value key for tree");
    }
    $jstree.select_node(id);
  });
};

export { setFieldValues };
