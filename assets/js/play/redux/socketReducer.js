import _ from "underscore";
import Anser from "anser";
import {createReducer} from "reduxsauce";

import {Types} from "./actions";

const INITIAL_STATE = {
  connected: false,
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

export const socketConnected = (state, action) => {
  const text = "\u001b[33mConnecting...\n\u001b[0m";
  state = parseText(state, text);
  return {...state, connected: true};
};

export const socketDisconnected = (state, action) => {
  if (!state.connected) {
    return state;
  }

  return {...state, connected: false};
};

export const socketEcho = (state, action) => {
  const {text} = action;
  return {...state, buffer: state.buffer + text};
};

export const socketGA = (state, action) => {
  if (state.buffer === "") {
    return state;
  }

  state = parseText(state, state.buffer);
  return {...state, buffer: ""};
};

export const socketReceiveConnection = (state, action) => {
  return {...state, connection: action.payload};
};

export const socketReceiveGMCP = (state, action) => {
  const {message, data} = action;
  return {...state, gmcp: {...state.gmcp, [message]: data}};
};

export const socketReceiveOption = (state, action) => {
  switch (action.key) {
    case "prompt_type": {
      return {...state, options: {...state.options, promptType: action.value}};
    }
    default: {
      return state;
    }
  }
};

export const HANDLERS = {
  [Types.SOCKET_CONNECTED]: socketConnected,
  [Types.SOCKET_DISCONNECTED]: socketDisconnected,
  [Types.SOCKET_ECHO]: socketEcho,
  [Types.SOCKET_GA]: socketGA,
  [Types.SOCKET_RECEIVE_CONNECTION]: socketReceiveConnection,
  [Types.SOCKET_RECEIVE_GMCP]: socketReceiveGMCP,
  [Types.SOCKET_RECEIVE_OPTION]: socketReceiveOption,
}

export const socketReducer = createReducer(INITIAL_STATE, HANDLERS);
