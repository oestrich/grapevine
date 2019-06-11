import {createActions} from 'reduxsauce';

export const {Types, Creators} = createActions({
  promptSetMessage: ["message"],
  promptSetActiveChannel: ["channel"],
  socketConnected: null,
  socketDisconnected: null,
  socketReceiveBroadcast: ["message"],
  socketSubscribeChannel: ["channel"],
});
