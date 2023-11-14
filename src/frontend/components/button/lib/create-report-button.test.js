import CreateReportButtonComponent from './create-report-button';
import { validateRequiredFields } from 'validation';

global.$ = require('jquery');

describe('create-report-button', () => {
  it('does not submit form if no checkboxes are checked', () => {
    document.body.innerHTML = `
      <form id="myform">
        <input class="form-control " id="report_name" name="report_name" value="Something" data-restore-value="" required="" aria-required="true">
        <input class="form-control " id="report_description" name="report_description" placeholder="New Report Description" value="" data-restore-value="">
        <fieldset class="fieldset fieldset--required" id="report_fields">
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
        <fieldset class="fieldset fieldset--required" id="report_fields">
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
        <fieldset class="fieldset fieldset--required" id="report_fields">
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
    formSpyFn.mockImplementation((ev) => { ev.preventDefault(); ev.stopPropagation(); });

    $('#myform').on('submit', formSpyFn);

    $('#submit').trigger('click');

    expect(submitSpy).toHaveBeenCalled();
    expect(formSpyFn).toHaveBeenCalled();
  });

  it('Validates checkboxes correctly', () => {
    document.body.innerHTML = `
      <form>
        <fieldset class="fieldset fieldset--required">
          <div class="fieldset__legend">
            <legend id="-label">
              Columns to show in report:
            </legend>
          </div>
          <div class="list list--vertical list--checkboxes">
            <ul class="list__items" id="">
              <li class="list__item">
                <input id="8" type="checkbox">
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="11" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="12" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="13" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="1" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="7" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="6" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="2" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="3" type="checkbox">
                </div>
              </li>
              <li class="list__item">
                <div class="checkbox ">
                  <input id="4" type="checkbox">
                </div>
              </li>
            </ul>
          </div>
        </fieldset>
        <button type="submit">
      </form>
    `;

    const fieldSet = $('form').find('.fieldset--required');

    expect(fieldSet.length).toBe(1);

    fieldSet.find('input').each((index, input) => {
      expect(input.checked).toBe(false);
    });

    expect(validateRequiredFields($('form'))).toBe(false);
  });
});