import _ from "underscore";
import Anser from "anser";
import { combineReducers, createStore } from 'redux';

// Actions
export const SOCKET_ECHO = "SOCKET_ECHO";
export const SOCKET_GA = "SOCKET_GA";
export const SOCKET_GMCP = "SOCKET_GMCP";
export const SOCKET_OPTION = "SOCKET_OPTION";

export const socketEcho = (text) => ({
  type: SOCKET_ECHO,
  payload: {text}
});

export const socketGA = () => ({
  type: SOCKET_GA,
});

export const socketReceiveGMCP = (message, data) => ({
  type: SOCKET_GMCP,
  payload: {message, data}
});

export const socketRecieveOption = ({key, value}) => ({
  type: SOCKET_OPTION,
  payload: {key, value},
});

// Selectors

export const getSocketState = (state) => {
  return state.socket;
}

export const getSocketLines = (state) => {
  return getSocketState(state).lines;
};

export const getSocketGMCP = (state) => {
  return getSocketState(state).gmcp;
};

// Reducers
const initialState = {
  buffer: "",
  lines: [],
  lineId: 0,
  gmcp: {},
}

let socketReducer = function(state = initialState, action) {
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

let rootReducer = combineReducers({socket: socketReducer});

export const store = createStore(rootReducer, window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__());
