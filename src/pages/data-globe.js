import { setupOtherUserViews } from "../components/other-user-view";
import { setupGlobeByClass } from "../components/globe";

const DataGlobePage = () => {
  $('.globe').each(function () {
    setupGlobeByClass($(this));
  });
  setupOtherUserViews();
}

export { DataGlobePage };
