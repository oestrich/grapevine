import _ from "underscore";
import Anser from "anser";
import {combineReducers, createStore} from 'redux';

import {
  PROMPT_CLEAR,
  PROMPT_HISTORY_ADD,
  PROMPT_HISTORY_SCROLL_BACKWARD,
  PROMPT_HISTORY_SCROLL_FORWARD,
  PROMPT_SET_CURRENT_TEXT,
  SOCKET_ECHO,
  SOCKET_GA,
  SOCKET_GMCP,
  SOCKET_OPTION,
} from "./actions";

// Selectors

export const getPromptState = (state) => {
  return state.prompt;
};

export const getPromptDisplayText = (state) => {
  return getPromptState(state).displayText;
};

export const getSocketState = (state) => {
  return state.socket;
};

export const getSocketPromptType = (state) => {
  return getSocketState(state).options.promptType;
};

export const getSocketLines = (state) => {
  return getSocketState(state).lines;
};

export const getSocketGMCP = (state) => {
  return getSocketState(state).gmcp;
};

// Reducers
const socketInitialState = {
  buffer: "",
  lines: [],
  lineId: 0,
  gmcp: {},
  options: {
    promptType: "text",
  },
}

let socketReducer = function(state = socketInitialState, action) {
  switch (action.type) {
    case SOCKET_ECHO: {
      const {text} = action.payload;
      return {...state, buffer: state.buffer + text};
    }
    case SOCKET_GA: {
      if (state.buffer === "") {
        return state;
      }

      let increment = 0;
      let parsedText = Anser.ansiToJson(state.buffer);

      parsedText = _.map(parsedText, text => {
        text = {
          id: state.lineId + increment,
          content: text.content,
          bg: text.bg,
          fg: text.fg,
          decoration: text.decoration
        };

        increment++;

        return text;
      });

      let lines = [...state.lines, ...parsedText];

      return {...state, buffer: "", lines: lines, lineId: state.lineId + increment};
    }
    case SOCKET_GMCP: {
      const {message, data} = action.payload;
      return {...state, gmcp: {...state.gmcp, [message]: data}};
    }
    case SOCKET_OPTION: {
      let option = action.payload;

      switch (option.key) {
        case "prompt_type": {
          return {...state, options: {...state.options, promptType: option.value}};
        }
        default: {
          return state;
        }
      }
    }
    default: {
      return state;
    }
  }
}

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

let rootReducer = combineReducers({prompt: promptReducer, socket: socketReducer});

export const store = createStore(rootReducer);
//  rootReducer,
//  window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
//);
