import './JQuerySearchableSelect';

export const refreshSelects = (el: JQuery<HTMLElement>) => {
    const ruleFilterSelects = [];
    const operatorSelects = [];

    el.on('afterCreateRuleFilters.queryBuilder', (e: JQuery.TriggeredEvent, rule: any) => {
        const ruleFilterSelect = $(rule.$el.find(`select[name=${rule.id}_filter]`));
        if (!ruleFilterSelects.includes(ruleFilterSelect[0])) ruleFilterSelects.push(ruleFilterSelect[0]);
        if (!ruleFilterSelect || !ruleFilterSelect[0]) {
            console.error('No select found');
            return;
        }
        if (ruleFilterSelect.data('searchableSelect')) return;
        ruleFilterSelect.searchableSelect();
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    el.on('afterCreateRuleOperators.queryBuilder', (e: JQuery.TriggeredEvent, rule: any) => {
        const operatorSelect = $(rule.$el.find(`select[name=${rule.id}_operator]`));
        if (!operatorSelect || !operatorSelect[0]) {
            console.error('No operator select found');
            return;
        }
        if (!operatorSelects.includes(operatorSelect[0])) operatorSelects.push(operatorSelect[0]);
        if (operatorSelect.data('searchableSelect')) return;
        operatorSelect.searchableSelect();
    });

    el.on('afterSetRules.queryBuilder', () => {
        for (const ruleFilterSelect of ruleFilterSelects) {
            if (!ruleFilterSelect) {
                continue;
            }
            $(ruleFilterSelect).getSearchableSelect()
                .refresh();
        }
        for (const operatorSelect of operatorSelects) {
            if (!operatorSelect) continue;
            $(operatorSelect).getSearchableSelect()
                .refresh();
        }
    });

    el.on('afterSetRuleOperator.queryBuilder', () => {
        for (const operatorSelect of operatorSelects) {
            if (!operatorSelect) {
                continue;
            }
            $(operatorSelect).getSearchableSelect()
                .refresh();
        }
    });
};
