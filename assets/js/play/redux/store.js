import {combineReducers, createStore} from 'redux';

import {promptReducer} from "./promptReducer";
import {socketReducer} from "./socketReducer";

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

let rootReducer = combineReducers({prompt: promptReducer, socket: socketReducer});

export const store = createStore(
  rootReducer,
  window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
);
