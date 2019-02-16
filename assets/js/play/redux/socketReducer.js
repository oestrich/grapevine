import _ from "underscore";
import Anser from "anser";
import {combineReducers, createStore} from 'redux';

import {Types} from "./actions";

const socketInitialState = {
  buffer: "",
  lines: [],
  lineId: 0,
  gmcp: {},
  options: {
    promptType: "text",
  },
}

let parseText = (state, text) => {
  let increment = 0;
  let parsedText = Anser.ansiToJson(text);

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

  return {...state, lines: lines, lineId: state.lineId + increment};
};

export const socketReducer = function(state = socketInitialState, action) {
  switch (action.type) {
    case Types.SOCKET_CONNECTED: {
      const text = "\u001b[33mConnecting...\n\u001b[0m";
      state = parseText(state, text);
      return {...state, connected: true};
    }
    case Types.SOCKET_DISCONNECTED: {
      if (!state.connected) {
        return state;
      }

      const text = "\u001b[31mDisconnected\n\u001b[0m";
      state = parseText(state, text);
      return {...state, connected: false};
    }
    case Types.SOCKET_ECHO: {
      const {text} = action;
      return {...state, buffer: state.buffer + text};
    }
    case Types.SOCKET_GA: {
      if (state.buffer === "") {
        return state;
      }

      state = parseText(state, state.buffer);
      return {...state, buffer: ""};
    }
    case Types.SOCKET_RECIEVE_GMCP: {
      const {message, data} = action;
      return {...state, gmcp: {...state.gmcp, [message]: data}};
    }
    case Types.SOCKET_RECIEVE_OPTION: {
      switch (action.key) {
        case "prompt_type": {
          return {...state, options: {...state.options, promptType: action.value}};
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
