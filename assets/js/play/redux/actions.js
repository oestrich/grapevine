export const PROMPT_SET_CURRENT_TEXT = "PROMPT_SET_CURRENT_TEXT";
export const PROMPT_CLEAR = "PROMPT_CLEAR";
export const PROMPT_HISTORY_ADD = "PROMPT_HISTORY_ADD";
export const PROMPT_HISTORY_SCROLL_BACKWARD = "PROMPT_HISTORY_SCROLL_BACKWARD";
export const PROMPT_HISTORY_SCROLL_FORWARD = "PROMPT_HISTORY_SCROLL_FORWARD";

export const SOCKET_ECHO = "SOCKET_ECHO";
export const SOCKET_GA = "SOCKET_GA";
export const SOCKET_GMCP = "SOCKET_GMCP";
export const SOCKET_OPTION = "SOCKET_OPTION";

export const promptSetCurrentText = (text) => ({
  type: PROMPT_SET_CURRENT_TEXT,
  payload: {text},
});

export const promptClear = () => ({
  type: PROMPT_CLEAR,
});

export const promptHistoryAdd = () => ({
  type: PROMPT_HISTORY_ADD,
});

export const promptHistoryScrollBackward = (message) => ({
  type: PROMPT_HISTORY_SCROLL_BACKWARD,
});

export const promptHistoryScrollForward = (message) => ({
  type: PROMPT_HISTORY_SCROLL_FORWARD,
});

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
