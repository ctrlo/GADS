// Bind events to a field to trigger validation
const initValidationOnField = (field) => {
  // Input
  if (field.hasClass('input--required')) {
    const $fileButton = field.find('.input__file-label')

    // Document
    if (field.hasClass('input--document')) {
      const $fieldset = field.closest('.fieldset');
      const $checkboxGroup = field.find('.list');
      const $checkBoxes = $checkboxGroup.find('input[type="checkbox"]')
      const $inputEl = field.find('.form-control-file')

      $fileButton.on('blur', (ev) => { validateCheckboxGroup($checkboxGroup) })
      $inputEl.on('change', (ev) => { validateCheckboxGroup($checkboxGroup) })
      $checkBoxes.on('blur change', (ev) => { validateCheckboxGroup($checkboxGroup) })

    // Other input types
    } else {
      const $inputEl = field.find('input[required]')
      const $fileButton = field.find('.input__file-label')
      
      $inputEl.on('blur change', (ev) => { setTimeout(() => { validateInput(field) }, 300)})
      $fileButton.on('blur', (ev) => { validateInput(field) } )
    }

  // Textarea
  } else if (field.hasClass('textarea--required')) {
    const $textareaEl = field.find('textarea[required]')
    $textareaEl.on('blur change', (ev) => { setTimeout(() => { validateInput(field) }, 300)})

  // Select
  } else if (field.hasClass('select--required')) {
    const $button = field.find('button')
    const $inputEl = field.find('input[required]')

    $button.on('blur', (ev) => { setTimeout(() => { validateInput(field) }, 300)})
    $inputEl.on('change', (ev) => { validateInput(field) } )

  // Radio-group
  } else if (field.hasClass('radio-group--required')) {
    const $radioButtons = field.find('input[required]')
    $radioButtons.on('blur change', (ev) => { setTimeout(() => { validateRadioGroup(field) }, 300)} )

  // Select-widget
  } else if (field.hasClass('select-widget--required')) {
      // Single select-widget
      if (!field.hasClass('multi')) {
        const $inputSearch = field.find('.form-control-search')
        const $radioButtons = field.find('input[required]')
        let inputBlurTimer

        $radioButtons.on('blur change', (ev) => { 
          inputBlurTimer = setTimeout(() => { 
            validateRadioGroup(field) 
          }, 300)} )

        $inputSearch.on('blur', (ev) => { 
          inputBlurTimer = setTimeout(() => { 
            validateRadioGroup(field) 
          }, 300)} )

        $radioButtons.on('focus', (ev) => { clearTimeout(inputBlurTimer) } )

      // Multi select-widget
      } else {
        const $inputSearch = field.find('.form-control-search')
        const $checkBoxes = field.find('input[type="checkbox"]')
        let inputBlurTimer

        $checkBoxes.on('blur change', (ev) => {
          inputBlurTimer = setTimeout(() => { 
            validateCheckboxGroup(field) 
          }, 300)} )
        
        $inputSearch.on('blur', (ev) => { 
          inputBlurTimer = setTimeout(() => { 
            validateCheckboxGroup(field) 
          }, 300)} )

        $checkBoxes.on('focus', (ev) => { clearTimeout(inputBlurTimer) } )

      }
  
  // Tree
  } else if (field.hasClass('tree--required')) {
    const $inputSearch = field.find('.selected-tree-value')
    const $jsTreeAnchors = field.find('.jstree-anchor')
    let anchorBlurTimer

    $jsTreeAnchors.on('blur change', (ev) => {
      anchorBlurTimer = setTimeout(() => { 
        validateTree(field) 
      }, 300)} )

    $jsTreeAnchors.on('focus', (ev) => { clearTimeout(anchorBlurTimer) } )

  }
}

// Validate the required fields of a form
const validateRequiredFields = (form) => {
  let isValidForm = true

  form.find(".input--required:not(.input--document), .textarea--required, .select--required").each((i, field) => {
    if (!validateInput($(field))) {
      expandCardValidate(field)
      isValidForm = false
    }
  })

  form.find(".input--document.input--required").each((i, field) => {
    if (!validateCheckboxGroup($(field).closest('.fieldset').find('.list'))) {
      expandCardValidate(field)
      isValidForm = false
    }
  })

  form.find(".radio-group--required").each((i, field) => {
    if (!validateRadioGroup($(field))) {
      expandCardValidate(field)
      isValidForm = false
    }
  })

  form.find(".select-widget--required").each((i, field) => {
    if (!$(field).hasClass('multi')) {
      if (!validateRadioGroup($(field))) {
        expandCardValidate(field)
        isValidForm = false
      }
    } else {
      if (!validateCheckboxGroup($(field))) {
        expandCardValidate(field)
        isValidForm = false
      }
    }
    
  })

  form.find(".tree--required").each((i, field) => {
    if (!validateTree($(field))) {
      $(field).closest('.card--expandable').find('.collapse').collapse('show')
      isValidForm = false
    }
  })

  return isValidForm
}

const addErrorMessage = (field, name, id) => {
  const $errorDiv = $('<div class="error">')
  let $span = $(`<span id="${id}-err" class="form-text form-text--error" aria-live="off"></span>`)
  $span.text(`${name} is a required field.`)
  $errorDiv.html($span)
  field.append($errorDiv)
}

const removeErrorMessage = (field) => {
  field.find('.error').remove()
}

const isHiddenDependentField = (field) => {
  return (field.closest(".form-group[data-has-dependency='1'][style*='display: none']").length > 0)
}

// Validate input field
const validateInput = (field) => {
  const $inputEl = field.find('[required]')
  const strFieldName = field.find('label').text() || ''
  const strID = $inputEl.attr('id') || ''

  removeErrorMessage($(field))

  if (($inputEl.val() === '') && (!isHiddenDependentField(field))) {
    $inputEl.attr('aria-invalid', true)
    addErrorMessage(field, strFieldName, strID)
    field.addClass('invalid')
    field.closest('.fieldset--required').addClass('fieldset--invalid')
    return false

  } else {
    $inputEl.removeAttr('aria-invalid')
    removeErrorMessage(field)
    field.removeClass('invalid')
    field.closest('.fieldset--required').removeClass('fieldset--invalid')
    return true

  }
}

// Validate radio-group
const validateRadioGroup = (field) => {
  const $radioButtons = field.find('input[required]')
  const $fieldSet = field.closest('.fieldset--required')
  const strFieldName = $fieldSet.find('.fieldset__legend legend').text() || ''
  const strID = field.attr('id') || ''
  let isChecked = false

  removeErrorMessage($(field))

  $radioButtons.each((i, radioButton) => {
    if ($(radioButton).is(":checked")) {
      isChecked = true
    }
  })

  if ((!isChecked) && (!isHiddenDependentField(field))) {
    $radioButtons.attr('aria-invalid', true)
    addErrorMessage(field, strFieldName, strID)
    field.addClass('invalid')
    field.closest('.fieldset--required').addClass('fieldset--invalid')
    return false

  } else {
    $radioButtons.removeAttr('aria-invalid')
    removeErrorMessage(field)
    field.removeClass('invalid')
    field.closest('.fieldset--required').removeClass('fieldset--invalid')
    return true

  }
}

// Validate checkbox group
const validateCheckboxGroup = (field) => {
  const $checkBoxes = field.find('input[type="checkbox"]')
  const $fieldSet = field.closest('.fieldset--required')
  const strFieldName = $fieldSet.find('.fieldset__legend legend').text() || ''
  const strID = field.attr('id') || ''
  let isChecked = false

  removeErrorMessage($(field))

  $checkBoxes.each((i, checkBox) => {
    if ($(checkBox).is(":checked")) {
      isChecked = true
    }
  })

  if ((!isChecked) && (!isHiddenDependentField(field))) {
    addErrorMessage(field, strFieldName, strID)
    field.addClass('invalid')
    field.closest('.fieldset--required').addClass('fieldset--invalid')
    return false

  } else {
    removeErrorMessage(field)
    field.removeClass('invalid')
    field.closest('.fieldset--required').removeClass('fieldset--invalid')
    return true
  }

}

// Validate tree
const validateTree = (field) => {
  const $inputEl = field.find('input[type="hidden"]')
  const $fieldSet = field.closest('.fieldset--required')
  const strFieldName = $fieldSet.find('.fieldset__legend legend').text() || ''
  const strID = field.attr('id') || ''

  removeErrorMessage($(field))

  if (((!$inputEl.length) || ($inputEl.val() === '')) && (!isHiddenDependentField(field))) {
    $inputEl.attr('aria-invalid', true)
    addErrorMessage(field, strFieldName, strID)
    field.addClass('invalid')
    field.closest('.fieldset--required').addClass('fieldset--invalid')
    return false

  } else {
    $inputEl.removeAttr('aria-invalid')
    removeErrorMessage(field)
    field.removeClass('invalid')
    field.closest('.fieldset--required').removeClass('fieldset--invalid')
    return true

  }
}

// Expand the card with a certain field and scroll it into view
const expandCardValidate = (field) => {
  const $collapse = $(field).closest('.card--expandable').find('.collapse')
  // If the card is already expanded then just scroll straight to the field
  if ($collapse.hasClass('show')) {
      field.scrollIntoView()
  } else {
    // Otherwise add an event handler to scroll to the field, but only once the
    // card has finished expanding (otherwise the scroll will happen before
    // the card has finished expanding and it won't work)
    $collapse.on('shown.bs.collapse.foobar', function(){
      field.scrollIntoView()
      $(this).off('shown.bs.collapse.foobar');
    })
    if($collapse && $collapse.collapse)
      $collapse.collapse('show')
  }
}

export { initValidationOnField, validateTree, validateRadioGroup, validateCheckboxGroup, validateRequiredFields };
