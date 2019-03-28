import _ from "underscore";
import Anser from "anser";
import {createReducer} from "reduxsauce";

import {Types} from "./actions";

const MAX_LINES = 5000;

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
  let parsedSegments = Anser.ansiToJson(text);

  parsedSegments = _.reject(parsedSegments, segment => {
    return segment.content === "";
  });

  parsedSegments = _.map(parsedSegments, segment => {
    return _.pick(segment, ["content", "bg", "fg", "decoration"]);
  });

  // Explode each segment into separate lines
  parsedSegments = _.map(parsedSegments, segment => {
    let lines = segment.content.split("\n");

    // There were no new lines
    if (lines.length == 1) {
      return [segment];
    }

    // Remove the empty item if there was a trailing newline already
    if (_.last(lines) === "") {
      lines.pop();
    }

    lines = _.map(lines, line => {
      return {...segment, content: line + "\n"};
    });

    // If the segment didn't end with a new line, remove the one that
    // is currently there
    if (_.last(segment.content) != "\n") {
      let line = lines.pop();
      line.content = line.content.slice(0, line.content.length - 1);
      lines = [...lines, line];
    }

    return lines;
  });

  parsedSegments = _.flatten(parsedSegments);

  parsedSegments = _.map(parsedSegments, segment => {
    segment.id = state.lineId + increment;
    increment++;
    return segment;
  });

  let lines = [...state.lines, ...parsedSegments];
  lines = _.last(lines, MAX_LINES);

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
