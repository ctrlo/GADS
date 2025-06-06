import "bootstrap";
import "bootstrap-select";
import "jQuery-QueryBuilder";

/**
 * Function to handle refreshing the selects used in the query builder that are bootstrap selects
 * @param {*} el The elements to refresh the selects for
 */
export const refreshSelects = (el) => {
  const ruleFilterSelects = [];
  const operatorSelects = [];

  el.on("afterCreateRuleFilters.queryBuilder", (e, rule) => {
    const ruleFilterSelect = $(rule.$el.find(`select[name=${rule.id}_filter]`));
    if (!ruleFilterSelects.includes(ruleFilterSelect)) ruleFilterSelects.push(ruleFilterSelect);
    if (!ruleFilterSelect || !ruleFilterSelect[0]) {
      console.error("No select found");
      return;
    }
    if(ruleFilterSelect.hasClass("form-select")) ruleFilterSelect.removeClass("form-select");
    ruleFilterSelect.data("live-search", "true");
    ruleFilterSelect.selectpicker();
  });

  el.on("afterCreateRuleOperators.queryBuilder", (e, rule) => {
    const operatorSelect = $(rule.$el.find(`select[name=${rule.id}_operator]`));
    if (!operatorSelect || !operatorSelect[0]) {
      console.error("No operator select found");
      return;
    }
    if (!operatorSelects.includes(operatorSelect)) operatorSelects.push(operatorSelect);
    if (operatorSelect.data("live-search")) return;
    if(operatorSelect.hasClass("form-select")) operatorSelect.removeClass("form-select");
    operatorSelect.data("live-search", "true");
    operatorSelect.selectpicker();
  });

  el.on("afterSetRules.queryBuilder", () => {
    for (const ruleFilterSelect of ruleFilterSelects) {
      if (!ruleFilterSelect) {
        continue;
      }
      $(ruleFilterSelect).selectpicker("destroy").selectpicker();
    }
    for (const operatorSelect of operatorSelects) {
      if (!operatorSelect || !operatorSelect.length) continue;
      operatorSelect.selectpicker("destroy").selectpicker();
    }
  });

  el.on("afterSetRuleOperator.queryBuilder", () => {
    for (const operatorSelect of operatorSelects) {
      if (!operatorSelect || !operatorSelect.length) {
        continue;
      }
      operatorSelect.selectpicker("destroy").selectpicker();
    }
  });
}