import _ from "underscore";

import {
  PROMPT_CLEAR,
  PROMPT_HISTORY_ADD,
  PROMPT_HISTORY_SCROLL_BACKWARD,
  PROMPT_HISTORY_SCROLL_FORWARD,
  PROMPT_SET_CURRENT_TEXT,
} from "./actions";

const promptInitialState = {
  index: -1,
  history: [],
  currentText: "",
  displayText: "",
}

export const promptReducer = (state = promptInitialState, action) => {
  switch (action.type) {
    case PROMPT_CLEAR: {
      return {...state, index: -1, currentText: "", displayText: ""};
    }
    case PROMPT_SET_CURRENT_TEXT: {
      const {text} = action.payload;
      return {...state, index: -1, currentText: text, displayText: text};
    }
    case PROMPT_HISTORY_ADD: {
      if (_.first(state.history) == state.displayText) {
        return {...state, index: -1};
      } else {
        let history = [state.displayText, ...state.history];
        history = _.first(history, 10);
        return {...state, history: history};
      }
    }
    case PROMPT_HISTORY_SCROLL_BACKWARD: {
      let index = state.index + 1;

      if (state.history[index] != undefined) {
        return {...state, index: index, displayText: state.history[index]};
      }

      return state;
    }
    case PROMPT_HISTORY_SCROLL_FORWARD: {
      let index = state.index - 1;

      if (index == -1) {
        return {...state, index: 0, displayText: state.currentText};
      } else if (state.history[index] != undefined) {
        return {...state, index: index, displayText: state.history[index]};
      }

      return state;
    }
    default: {
      return state;
    }
  }
}
