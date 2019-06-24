import _ from "underscore";
import {createReducer} from "reduxsauce";
import * as ansi from "@grapevine/ansi";

import {Types} from "./actions";

const INITIAL_STATE = {
  modals: [],
}

class Modal {
  constructor(attrs) {
    this.key = attrs.key;
    this.title = attrs.title;
    this.lines = ansi.parse(attrs.body);
  }
}

export const modalClose = (state, action) => {
  let modals = _.reject(state.modals, (modal) => {
    return modal.key == action.key;
  });

  return {...state, modals: modals};
}

export const modalOpen = (state, action) => {
  let modals = _.reject(state.modals, (modal) => {
    return modal.key == action.data.key;
  });
  let modal = new Modal(action.data);

  return {...state, modals: [...modals, modal]};
}

export const modalReceiveGMCP = (state, action) => {
  switch (action.message) {
    case "Client.Modals.Open":
      return modalOpen(state, action);

    default:
      return state;
  }
};

export const HANDLERS = {
  [Types.MODALS_CLOSE]: modalClose,
  [Types.SOCKET_RECEIVE_GMCP]: modalReceiveGMCP,
}

export const modalReducer = createReducer(INITIAL_STATE, HANDLERS);
