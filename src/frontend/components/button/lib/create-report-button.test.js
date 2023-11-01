import $ from 'jquery';
import CreateReportButtonComponent from './create-report-button';

global.$ = $;

describe('create-report-button', () => {
  it('does not validate if no checkboxes are checked', () => {
    document.body.innerHTML = `
      <fieldset class="fieldset fieldset--required fieldset--report" id="report_fields">
        <input id="1" type="checkbox">
        <input id="8" type="checkbox">
        <input id="2" type="checkbox">
        <input id="3" type="checkbox">
        <input id="4" type="checkbox">
        <input id="1" type="checkbox">
        <input id="6" type="checkbox">
        <input id="7" type="checkbox">
      </fieldset>
    `

    const button = new CreateReportButtonComponent(document.body);

    const $fieldset = $(".fieldset--report");
    const checked = button.checkForAtLeastOneValue($fieldset);

    expect(checked).toBeFalsy();
  });

  it('does not submit form if no checkboxes are checked', () => {
    document.body.innerHTML = `
      <form id="myform">
        <input class="form-control " id="report_name" name="report_name" value="Something" data-restore-value="" required="" aria-required="true">
        <input class="form-control " id="report_description" name="report_description" placeholder="New Report Description" value="" data-restore-value="">
        <fieldset class="fieldset fieldset--required fieldset--report" id="report_fields">
          <input id="1" type="checkbox">
          <input id="8" type="checkbox">
          <input id="2" type="checkbox">
          <input id="3" type="checkbox">
          <input id="4" type="checkbox">
          <input id="1" type="checkbox">
          <input id="6" type="checkbox">
          <input id="7" type="checkbox">
        </fieldset>
        <button type="submit" class="btn btn-inverted btn-js-report" id="submit">
      </form>
    `;

    const button = new CreateReportButtonComponent(document.getElementById('submit'));

    const submitSpy = jest.spyOn(button, 'submit');

    $('#submit').trigger('click');

    expect(submitSpy).not.toHaveBeenCalled();
  });

  it('does not submit on required values missing', () => {
    document.body.innerHTML = `
      <form id="myform">
        <div class="input--required">
          <input required="" aria-required="true">
        </div>
        <input>
        <fieldset class="fieldset fieldset--required fieldset--report" id="report_fields">
          <input id="1" type="checkbox">
          <input id="8" type="checkbox" checked="checked">
          <input id="2" type="checkbox">
          <input id="3" type="checkbox" checked="checked">
          <input id="4" type="checkbox">
          <input id="1" type="checkbox">
          <input id="6" type="checkbox">
          <input id="7" type="checkbox">
        </fieldset>
        <button type="submit" class="btn btn-inverted btn-js-report" id="submit">
      </form>
    `;

    const button = new CreateReportButtonComponent(document.getElementById('submit'));

    const submitSpy = jest.spyOn(button, 'submit');

    $('#submit').trigger('click');

    expect(submitSpy).not.toHaveBeenCalled();
  });

  it('does submit fully on required values present', () => {
    document.body.innerHTML = `
      <form id="myform">
        <div class="input--required">
          <input required="" aria-required="true" value = "boop">
        </div>
        <input>
        <fieldset class="fieldset fieldset--required fieldset--report" id="report_fields">
          <input id="1" type="checkbox">
          <input id="8" type="checkbox" checked="checked">
          <input id="2" type="checkbox">
          <input id="3" type="checkbox" checked="checked">
          <input id="4" type="checkbox">
          <input id="1" type="checkbox">
          <input id="6" type="checkbox">
          <input id="7" type="checkbox">
        </fieldset>
        <button type="submit" class="btn btn-inverted btn-js-report" id="submit">
      </form>
    `;

    const button = new CreateReportButtonComponent(document.getElementById('submit'));

    const submitSpy = jest.spyOn(button, 'submit');
    const formSpyFn = jest.fn();
    formSpyFn.mockImplementation((ev) => { ev.preventDefault(); });

    $('#myform').on('submit', formSpyFn);

    $('#submit').trigger('click');

    expect(submitSpy).toHaveBeenCalled();
    expect(formSpyFn).toHaveBeenCalled();
  });
});