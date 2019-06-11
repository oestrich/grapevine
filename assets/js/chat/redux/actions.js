import {createActions} from 'reduxsauce';

export const {Types, Creators} = createActions({
  socketConnected: null,
  socketDisconnected: null,
  socketReceiveBroadcast: ["message"],
  socketSetActiveChannel: ["channel"],
  socketSubscribeChannel: ["channel"],
});
