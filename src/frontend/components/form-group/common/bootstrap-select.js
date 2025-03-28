import "bootstrap-select";

/**
 * Refreshes the select pickers in the query builder
 * @param {*} el The element that the select is attached to
 */
export const refreshSelects = (el) => {
  const ruleFilterSelects = [];
  const operatorSelects = [];

  if (typeof bootstrap == "undefined" || !bootstrap) {
    console.error("Bootstrap is not loaded");
    return;
  }

  el.on("afterCreateRuleFilters.queryBuilder", (e, rule) => {
    const ruleFilterSelect = $(rule.$el.find(`select[name=${rule.id}_filter]`));
    if (!ruleFilterSelects.includes(ruleFilterSelect[0])) ruleFilterSelects.push(ruleFilterSelect[0]);
    if (!ruleFilterSelect || !ruleFilterSelect[0]) {
      console.error("No select found");
      return;
    }
    ruleFilterSelect.data("live-search", "true");
    ruleFilterSelect.selectpicker();
  });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  el.on("afterCreateRuleOperators.queryBuilder", (e, rule, operators) => {
    const operatorSelect = $(rule.$el.find(`select[name=${rule.id}_operator]`));
    if (!operatorSelect || !operatorSelect[0]) {
      console.error("No operator select found");
      return;
    }
    if (!operatorSelects.includes(operatorSelect[0])) operatorSelects.push(operatorSelect[0]);
    if (operatorSelect.data("live-search")) return;
    operatorSelect.data("live-search", "true");
    operatorSelect.selectpicker();
  });

  el.on("afterSetRules.queryBuilder", () => {
    for (const ruleFilterSelect of ruleFilterSelects) {
      if (!ruleFilterSelect) {
        continue;
      }
      $(ruleFilterSelect).selectpicker("refresh");
    }
    for (const operatorSelect of operatorSelects) {
      if (!operatorSelect) continue;
      $(operatorSelect).selectpicker("refresh");
    }
  });

  el.on("afterSetRuleOperator.queryBuilder", () => {
    for (const operatorSelect of operatorSelects) {
      if (!operatorSelect) {
        continue;
      }
      $(operatorSelect).selectpicker("refresh");
    }
  });
}