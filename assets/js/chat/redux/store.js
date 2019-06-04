import {combineReducers, createStore, applyMiddleware, compose} from 'redux';

import {socketReducer} from "./socket_reducer";

let rootReducer = combineReducers({
  socket: socketReducer,
});

const composeEnhancers =
  typeof window === 'object' && window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ ?
    window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({}) : compose;

const enhancer = composeEnhancers();

export const makeStore = () => {
  return createStore(rootReducer, enhancer);
};
