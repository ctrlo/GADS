import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import ExpandableCardComponent from './component';

describe('ExpandableCardComponent', () => {
    beforeEach(() => {
        document.body.innerHTML = `
<div class="content-block">
  <div id="target" class="card card--expandable">
    <div class="card__header">
      <button class="card__header-left" type="button" data-bs-toggle="collapse" data-target="#topic" aria-expanded="false"
        aria-controls="topic">
        <span class="card__title">Other</span>
      </button>
      <div class="card__header-right">
        <button type="button" class="btn btn-edit btn-js-edit">
          <span class="btn__title">Edit</span>
        </button>
        <button type="button" class="btn btn-view btn-js-view">
          <span class="btn__title">View</span>
        </button>
        <button class="card__toggle" type="button" data-bs-toggle="collapse" data-target="#topic" aria-expanded="true"
          aria-controls="topic">
          <span>Toggle collapsible</span>
        </button>
      </div>
    </div>
    <div class="collapse show" id="topic">
      <div class="card__content">
        <div class="card__view-content">
          <div class="list list--vertical list--key-value list--no-borders list--fields">
            <ul class="list__items list-group list-group-flush">
              <li class="list__item list-group-item">
                <span class="list__key">Surname</span>
                <span class="list__value">
                  <div class="hft-lines">Pig<br></div>
                </span>
              </li>
              <li class="list__item list-group-item">
                <span class="list__key">Forename</span>
                <span class="list__value">
                  <div class="hft-lines">Daddy<br></div>
                </span>
              </li>
              <li class="list__item list-group-item">
                <span class="list__key">Full Name</span>
                <span class="list__value">
                  <div class="hft-lines">Daddy Pig<br></div>
                </span>
              </li>
              <li class="list__item list-group-item">
                <span class="list__key">Age</span>
                <span class="list__value">9783</span>
              </li>
            </ul>
          </div>
        </div>
        <div class="card__edit-content">
          <div class="form-group linkspace-field" data-column-id="74" data-column-type="string" data-value-selector=""
            data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Surname"
            data-name-short="sname" data-dependent-not-shown="0" style="margin-left:0px">
            <div class="input  input--required">
              <div class="input__label">
                <label for="74">Surname</label>
              </div>
              <div class="input__field">
                <input type="text" class="form-control " id="74" name="field74" placeholder="" value="Pig"
                  data-restore-value="Pig" required="" aria-required="true">
              </div>
            </div>
          </div>
          <div class="form-group linkspace-field" data-column-id="75" data-column-type="string" data-value-selector=""
            data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Forename"
            data-name-short="fname" data-dependent-not-shown="0" style="margin-left:0px">
            <div class="input  input--required">
              <div class="input__label">
                <label for="75">Forename</label>
              </div>
              <div class="input__field">
                <input type="text" class="form-control " id="75" name="field75" placeholder="" value="Daddy"
                  data-restore-value="Daddy" required="" aria-required="true">
              </div>
            </div>
          </div>
          <div class="form-group linkspace-field" data-column-id="76" data-column-type="calc" data-value-selector=""
            data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Full Name" data-name-short=""
            data-calc-depends-on="Wzc1LDc0XQ=="
            data-code="ZnVuY3Rpb24gZXZhbHVhdGUgKGZuYW1lLCBzbmFtZSkNCg0KaWYgZm5hbWUgPT0gbmlsIHRoZW4gcmV0dXJuIGVuZA0KaWYgc25hbWUgPT0gbmlsIHRoZW4gcmV0dXJuIGVuZA0KDQpyZXR1cm4gZm5hbWUgLi4gIiAiIC4uIHNuYW1lDQoNCmVuZA=="
            data-code-params="WyJmbmFtZSIsInNuYW1lIl0=" data-is-readonly="true" data-dependent-not-shown="0"
            style="margin-left:0px">
            <div class="textarea ">
              <div class="textarea__label">
                <label for="">Full Name</label>
              </div>
              <div class="input__field w-100">
                <textarea class="form-control auto-adjust" id="76" name="field76" rows="" placeholder="" readonly=""
                  style="height: 2.5rem;">Daddy Pig</textarea>
              </div>
            </div>
          </div>
          <div class="form-group linkspace-field" data-column-id="77" data-column-type="intgr" data-value-selector=""
            data-show-add="" data-modal-field-ids="" data-curval-instance-name="" data-name="Age" data-name-short=""
            data-dependent-not-shown="0" style="margin-left:0px">
            <div class="input  input--required">
              <div class="input__label">
                <label for="77">Age</label>
              </div>
              <div class="input__field">
                <input type="number" class="form-control " id="77" name="field77" placeholder="" value="9783"
                  data-restore-value="9783" required="" aria-required="true">
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
`;
    });

    afterEach(() => {
        document.body.innerHTML = '';
    });

    describe('Without topic', () => {
        it('Should create an expandable card component', () => {
            const target = document.getElementById('target');
            expect(target).not.toBeNull();
            expect(target?.dataset.componentInitializedExpandablecardcomponent).toBeUndefined();
            new ExpandableCardComponent(target as HTMLElement);
            expect(target?.dataset.componentInitializedExpandablecardcomponent).toBe('true');
            expect(target?.classList.contains('card--edit')).toBe(false);
        });

        it('Should go into edit mode', () => {
            const target = document.getElementById('target');
            if (!target) throw new Error('Target not found');
            new ExpandableCardComponent(target as HTMLElement);
            const editButton = target.querySelector('.btn-js-edit') as HTMLButtonElement;
            expect(editButton).not.toBeNull();
            editButton.click();
            expect(target.classList.contains('card--edit')).toBe(true);
        });

        it('Should go into view mode', () => {
            const target = document.getElementById('target');
            if (!target) throw new Error('Target not found');
            new ExpandableCardComponent(target as HTMLElement);
            const editButton = target.querySelector('.btn-js-edit') as HTMLButtonElement;
            expect(editButton).not.toBeNull();
            editButton.click();
            expect(target.classList.contains('card--edit')).toBe(true);
            const viewButton = target.querySelector('.btn-js-view') as HTMLButtonElement;
            expect(viewButton).not.toBeNull();
            viewButton.click();
            expect(target.classList.contains('card--edit')).toBe(false);
        });
    });

    describe('With topic', () => {
        beforeEach(() => {
            const target = document.getElementById('target');
            if (!target) throw new Error('Target not found');
            target?.classList.add('card--topic');
        });

        it('should create an expandable topic component', () => {
            const target = document.getElementById('target');
            if (!target) throw new Error('Target not found');
            // Set the items in the card to be invisible, as if there was nothing to show
            const $target = $(target);
            $target.find('.list--fields').find('ul li')
                .each((_i, el) => {
                    $(el).css('display', 'none');
                });
            $target.find('.linkspace-field').each((_i, el) => {
                $(el).css('display', 'none');
            });
            new ExpandableCardComponent(target as HTMLElement);
            expect(target?.dataset.componentInitializedExpandablecardcomponent).toBe('true');
            // We expect the card to be hidden
            expect(target?.style.display).toBe('none');
        });
    });
});
