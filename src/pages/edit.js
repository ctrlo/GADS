import { setupTreeFields } from "../components/tree-fields";
import { setupDependentFields } from "../components/dependent-fields";
import { setupCalcFields } from "../components/calc-fields";
import { setupClickToEdit } from "../components/click-to-edit";
import { setupClickToViewBlank } from "../components/click-to-view-blank";
import { setupCalculator } from "../components/calculator";
import { setupZebraTable } from "../components/zebra-table";

const EditPage = context => {
  Linkspace.debug("Record edit JS firing");
  setupTreeFields(context);
  setupDependentFields(context);
  setupCalcFields(context);
  setupClickToEdit(context);
  setupClickToViewBlank(context);
  setupCalculator(context);
  setupZebraTable(context);
};

export { EditPage };
