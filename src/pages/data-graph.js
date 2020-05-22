import { setupOtherUserViews } from "../components/other-user-view";
import { setupGraph } from "../components/graph";

const DataGraphPage = context => {
  setupOtherUserViews();
  setupGraph(context);
};

export { DataGraphPage };
