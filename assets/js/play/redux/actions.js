import {createActions} from 'reduxsauce';

export const {Types, Creators} = createActions({
  promptSetCurrentText: ["text"],
  promptClear: null,
  promptHistoryAdd: null,
  promptHistoryScrollBackward: ["message"],
  promptHistoryScrollForward: ["message"],
  socketConnected: null,
  socketDisconnected: null,
  socketEcho: ["text"],
  socketGA: null,
  socketReceiveGMCP: ["message", "data"],
  socketReceiveOption: ({key, value}) => ({type: "SOCKET_RECEIVE_OPTION", key, value})
});
