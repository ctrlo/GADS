import {Component} from "component";
import {MarkDown} from "util/formatters/markdown";

/**
 * @class HelpView
 * @extends Component
 * @description A component that displays help text in a target.
 */
export default class HelpView extends Component {
  // This is protected so that it can be accessed in tests.
  protected $button: JQuery<HTMLAnchorElement>;

  /**
   * @constructor Create a new HelpView component.
   * @param element The Element to attach the component to.
   */
  constructor(element: HTMLElement) {
    super(element);
    this.initHelp(element);
  }

  /**
   * @method initHelp
   * @description Initialize the help view.
   * @param element The element to attach the help view to.
   */
  initHelp(element: HTMLElement) {
    const $el = $(element);
    const $label = $el.find("label").parent();
    // Yes, I know it's not a button, but $a just didn't feel right!
    const $button = $(document.createElement("a"));
    if ($label && $label.length > 0) {
      $button.addClass("btn").addClass("btn-plain").addClass("btn-help").attr("role", "button").attr("type", "button");
      $label.first().append($button);
    }
    this.$button = $button;
    const helpText = $el.data("help-text");
    if (!helpText) throw new Error("help-text is required");
    const helpTitle = $el.data("help-title");
    const helpTarget = $el.data("help-target");
    if (!helpTarget) throw new Error("help-target is required");
    const target = document.getElementById(helpTarget);
    if (!target) throw new Error(`Could not find help target with id: ${helpTarget}`);
    $button.on("click", () => {
      target.innerHTML = MarkDown`${helpTitle ? `### ${helpTitle}` : ""}\n${helpText}`;
    });
  }
}
