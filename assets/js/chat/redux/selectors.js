export const getSocketState = (state) => {
  return state.socket;
};

export const getSocketActiveChannel = (state) => {
  return getSocketState(state).activeChannel;
};

export const getSocketChannels = (state) => {
  return getSocketState(state).channels;
};

export const getSocketConnected = (state) => {
  return getSocketState(state).connected;
};

export const getSocketMessages = (state) => {
  return getSocketState(state).messages;
};
