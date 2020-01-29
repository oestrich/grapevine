import {combineReducers, createStore, applyMiddleware, compose} from 'redux';
import thunk from 'redux-thunk';

import {promptReducer} from "./promptReducer";
import {socketReducer} from "./socketReducer";

let rootReducer = combineReducers({
  prompt: promptReducer,
  socket: socketReducer,
});

const composeEnhancers =
  typeof window === 'object' && window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ ?
    window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({}) : compose;

const enhancer = composeEnhancers(applyMiddleware(thunk));

export const makeStore = () => {
  return createStore(rootReducer, enhancer);
};
