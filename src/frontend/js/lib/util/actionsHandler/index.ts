// We load all the actions in this file, nowhere else. This is to preserve encapsulation.
import './lib/clearAutorecoverAction';
import { handleActions } from './lib/handler';

export default handleActions;
