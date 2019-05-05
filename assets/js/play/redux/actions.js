import {createActions} from 'reduxsauce';

export const {Types, Creators} = createActions({
  modalsClose: ["key"],
  promptSetCurrentText: ["text"],
  promptClear: null,
  promptHistoryAdd: null,
  promptHistoryScrollBackward: ["message"],
  promptHistoryScrollForward: ["message"],
  settingsSetFont: ["font"],
  settingsSetFontSize: ["fontSize"],
  settingsToggle: null,
  socketConnected: null,
  socketDisconnected: null,
  socketEcho: ["text"],
  socketGA: null,
  socketOAuthClose: null,
  socketReceiveConnection: ({type, host, port}) => ({type: "SOCKET_RECEIVE_CONNECTION", payload: {type, host, port}}),
  socketReceiveGMCP: ["message", "data"],
  socketReceiveOAuth: ["message"],
  socketReceiveOption: ({key, value}) => ({type: "SOCKET_RECEIVE_OPTION", key, value})
});
