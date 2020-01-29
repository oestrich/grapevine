export const getPromptState = (state) => {
  return state.prompt;
};

export const getPromptActiveChannel = (state) => {
  return getPromptState(state).activeChannel;
};

export const getPromptMessage = (state) => {
  return getPromptState(state).message;
};

export const getSocketState = (state) => {
  return state.socket;
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
