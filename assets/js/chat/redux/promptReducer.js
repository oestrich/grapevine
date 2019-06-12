import _ from "underscore";
import {createReducer} from "reduxsauce";

import {Types} from "./actions";

const INITIAL_STATE = {
  activeChannel: null,
  channels: [],
  message: "",
};

export const setActiveChannel = (state, action) => {
  const {channel} = action;
  return {...state, activeChannel: channel};
};

export const setMessage = (state, action) => {
  const {message} = action;

  let channel = _.find(state.channels, (channel) =>{
    return `/${channel} ` === message;
  });

  if (channel != undefined) {
    return {...state, activeChannel: channel, message: ""};
  }

  return {...state, message: message};
};

export const subscribeChannel = (state, action) => {
  const {channel} = action;

  state = {...state, channels: [...state.channels, channel]};

  if (state.activeChannel === null) {
    return {...state, activeChannel: channel};
  }

  return state;
};

const HANDLERS = {
  [Types.PROMPT_SET_ACTIVE_CHANNEL]: setActiveChannel,
  [Types.PROMPT_SET_MESSAGE]: setMessage,
  [Types.SOCKET_SUBSCRIBE_CHANNEL]: subscribeChannel,
};

export const promptReducer = createReducer(INITIAL_STATE, HANDLERS);
