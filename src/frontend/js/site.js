import "regenerator-runtime/runtime.js"
import { initializeRegisteredComponents, registerComponent } from 'component'
import 'bootstrap'
import 'components/graph/lib/chart'

// Components
import AddTableModalComponent from 'components/modal/modals/new-table'
import ButtonComponent from 'components/button'
import CalcFieldsComponent from 'components/form-group/calc-fields'
import CalculatorComponent from 'components/calculator'
import CheckboxComponent from 'components/form-group/checkbox'
import CollapsibleComponent from 'components/collapsible'
import CurvalModalComponent from 'components/modal/modals/curval'
import DashboardComponent from 'components/dashboard'
import DataTableComponent from 'components/data-table'
import DependentFieldsComponent from 'components/form-group/dependent-fields'
import DisplayConditionsComponent from 'components/form-group/display-conditions'
import ExpandableCardComponent from 'components/card'
import FilterComponent from 'components/form-group/filter'
import GlobeComponent from 'components/globe'
import GraphComponent from 'components/graph'
import InputComponent from 'components/form-group/input'
import MoreLessComponent from 'components/more-less'
import MultipleSelectComponent from 'components/form-group/multiple-select'
import OrderableSortableComponent from 'components/sortable/orderable-sortable'
import PopoverComponent from 'components/popover'
import RadioGroupComponent from 'components/form-group/radio-group'
import RecordPopupComponent from 'components/record-popup'
import SelectComponent from 'components/form-group/select'
import SelectWidgetComponent from 'components/form-group/select-widget'
import SidebarComponent from 'components/sidebar'
import SortableComponent from 'components/sortable'
import SummerNoteComponent from 'components/summernote'
import TextareaComponent from 'components/form-group/textarea'
import TimelineComponent from 'components/timeline'
import TippyComponent from 'components/timeline/tippy'
import TreeComponent from 'components/form-group/tree'
import UserModalComponent from 'components/modal/modals/user'
import ValueLookupComponent from 'components/form-group/value-lookup'
import MoreInfoButton from "components/buttons/more-info-button"

// Register them
registerComponent(AddTableModalComponent)
registerComponent(ButtonComponent)
registerComponent(CalcFieldsComponent)
registerComponent(CalculatorComponent)
registerComponent(CheckboxComponent)
registerComponent(CollapsibleComponent)
registerComponent(CurvalModalComponent)
registerComponent(DashboardComponent)
registerComponent(DataTableComponent)
registerComponent(DependentFieldsComponent)
registerComponent(DisplayConditionsComponent)
registerComponent(ExpandableCardComponent)
registerComponent(FilterComponent)
registerComponent(GlobeComponent)
registerComponent(GraphComponent)
registerComponent(InputComponent)
registerComponent(MoreLessComponent)
registerComponent(MultipleSelectComponent)
registerComponent(OrderableSortableComponent)
registerComponent(PopoverComponent)
registerComponent(RadioGroupComponent)
registerComponent(RecordPopupComponent)
registerComponent(SelectComponent)
registerComponent(SelectWidgetComponent)
registerComponent(SidebarComponent)
registerComponent(SortableComponent)
registerComponent(SummerNoteComponent)
registerComponent(TextareaComponent)
registerComponent(TimelineComponent)
registerComponent(TippyComponent)
registerComponent(TreeComponent)
registerComponent(UserModalComponent)
registerComponent(ValueLookupComponent)
registerComponent(MoreInfoButton)

// Initialize all components at some point
initializeRegisteredComponents(document.body)
