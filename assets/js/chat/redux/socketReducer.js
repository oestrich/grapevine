import {createActions, createReducer} from "reduxsauce";

export const {Types: SocketTypes, Creators: SocketCreators} = createActions({
  socketConnected: null,
  socketDisconnected: null,
  socketReceiveBroadcast: ["message"],
  socketSubscribedChannel: ["channel"],
});

SocketCreators.socketSubscribeChannel = (socket, channelName) => {
  return (dispatch) => {
    socket.connectChannel(channelName);
    dispatch(SocketCreators.socketSubscribedChannel(channelName));
  };
};

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

export const socketSubscribedChannel = (state, action) => {
  const {channel} = action;

  state = {...state, channels: [...state.channels, channel]};

  if (state.channels.length == 1) {
    return {...state, activeChannel: channel};
  }

  return state;
};

const HANDLERS = {
  [SocketTypes.SOCKET_CONNECTED]: socketConnected,
  [SocketTypes.SOCKET_DISCONNECTED]: socketDisconnected,
  [SocketTypes.SOCKET_RECEIVE_BROADCAST]: socketReceiveBroadcast,
  [SocketTypes.SOCKET_SUBSCRIBED_CHANNEL]: socketSubscribedChannel,
};

export const socketReducer = createReducer(INITIAL_STATE, HANDLERS);
