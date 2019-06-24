import _ from "underscore";
import {createReducer} from "reduxsauce";
import * as ansi from "@grapevine/ansi";
import {InputSequence} from "@grapevine/ansi/dist/models";

import {Types} from "./actions";

const MAX_LINES = 1000;

const INITIAL_STATE = {
  connected: false,
  buffer: "",
  lines: [],
  lastLine: null,
  lineId: 0,
  gmcp: {},
  oauth: null,
  options: {
    promptType: "text",
  },
}

let appendLines = (state, lines) => {
  let increment = 0;
  lines = lines.map(line => {
    line.id = state.lineId + increment;
    increment++;
    return line;
  });

  lines = [...state.lines, ...lines];
  lines = _.last(lines, MAX_LINES);
  let lastLine = lines.pop();

  return {...state, lastLine: lastLine, lines: lines, lineId: state.lineId + increment};
};

let parseText = (state, text) => {
  let lines = ansi.parse(text, state.lastLine);
  return appendLines(state, lines);
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

export const socketInput = (state, action) => {
  const {text} = action;
  let lines = ansi.appendInput(state.lastLine, text);
  return appendLines(state, lines);
};

export const socketGA = (state, action) => {
  if (state.buffer === "") {
    return state;
  }

  state = parseText(state, state.buffer);
  return {...state, buffer: ""};
};

export const socketOAuthClose = (state, action) => {
  return {...state, oauth: null};
};

export const socketReceiveConnection = (state, action) => {
  return {...state, connection: action.payload};
};

export const socketReceiveGMCP = (state, action) => {
  const {message, data} = action;
  return {...state, gmcp: {...state.gmcp, [message]: data}};
};

export const socketReceiveOAuth = (state, action) => {
  const {message} = action;

  if (message.event == "start") {
    return {...state, oauth: {status: "authorizing", scopes: message.scopes}};
  }

  return state;
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
  [Types.SOCKET_INPUT]: socketInput,
  [Types.SOCKET_GA]: socketGA,
  [Types.SOCKET_O_AUTH_CLOSE]: socketOAuthClose,
  [Types.SOCKET_RECEIVE_CONNECTION]: socketReceiveConnection,
  [Types.SOCKET_RECEIVE_GMCP]: socketReceiveGMCP,
  [Types.SOCKET_RECEIVE_O_AUTH]: socketReceiveOAuth,
  [Types.SOCKET_RECEIVE_OPTION]: socketReceiveOption,
}

export const socketReducer = createReducer(INITIAL_STATE, HANDLERS);
