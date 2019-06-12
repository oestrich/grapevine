import {createReducer} from "reduxsauce";

import {Types} from "./actions";

export const INITIAL_STATE = {
  channels: [],
  connected: false,
  messages: [],
};

export const socketConnected = (state, action) => {
  const message = {
    type: "system",
    text: "Connected",
    color: "green",
  };

  return {...state, connected: true, messages: [...state.messages, message]};
};

export const socketDisconnected = (state, action) => {
  if (!state.connected) {
    return state;
  }

  const message = {
    type: "system",
    text: "Disconnected",
    color: "red",
  };

  return {...state, connected: false, messages: [...state.messages, message]};
};

export const socketReceiveBroadcast = (state, action) => {
  const {message} = action;
  return {...state, messages: [...state.messages, {...message, type: "broadcast"}]};
};

export const socketSubscribeChannel = (state, action) => {
  const {channel} = action;

  state = {...state, channels: [...state.channels, channel]};

  if (state.channels.length == 1) {
    return {...state, activeChannel: channel};
  }

  return state;
};

const HANDLERS = {
  [Types.SOCKET_CONNECTED]: socketConnected,
  [Types.SOCKET_DISCONNECTED]: socketDisconnected,
  [Types.SOCKET_RECEIVE_BROADCAST]: socketReceiveBroadcast,
  [Types.SOCKET_SUBSCRIBE_CHANNEL]: socketSubscribeChannel,
};

export const socketReducer = createReducer(INITIAL_STATE, HANDLERS);
