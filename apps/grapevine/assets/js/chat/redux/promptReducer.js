import _ from "underscore";
import {createActions, createReducer} from "reduxsauce";

import {SocketTypes} from "./socketReducer";

export const {Types: PromptTypes, Creators: PromptCreators} = createActions({
  promptSetMessage: ["message"],
  promptSetActiveChannel: ["channel"],
});

export const INITIAL_STATE = {
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

export const subscribedChannel = (state, action) => {
  const {channel} = action;

  state = {...state, channels: [...state.channels, channel]};

  if (state.activeChannel === null) {
    return {...state, activeChannel: channel};
  }

  return state;
};

const HANDLERS = {
  [PromptTypes.PROMPT_SET_ACTIVE_CHANNEL]: setActiveChannel,
  [PromptTypes.PROMPT_SET_MESSAGE]: setMessage,
  [SocketTypes.SOCKET_SUBSCRIBED_CHANNEL]: subscribedChannel,
};

export const promptReducer = createReducer(INITIAL_STATE, HANDLERS);
