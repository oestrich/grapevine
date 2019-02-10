import _ from "underscore";
import Anser from "anser";
import {combineReducers, createStore} from 'redux';

import {
  SOCKET_ECHO,
  SOCKET_GA,
  SOCKET_GMCP,
  SOCKET_OPTION,
} from "./actions";

const socketInitialState = {
  buffer: "",
  lines: [],
  lineId: 0,
  gmcp: {},
  options: {
    promptType: "text",
  },
}

export const socketReducer = function(state = socketInitialState, action) {
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
