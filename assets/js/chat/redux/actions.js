import {createActions} from 'reduxsauce';

const {Types, Creators} = createActions({
  promptSetMessage: ["message"],
  promptSetActiveChannel: ["channel"],
  socketConnected: null,
  socketDisconnected: null,
  socketReceiveBroadcast: ["message"],
  socketSubscribedChannel: ["channel"],
});

Creators.socketSubscribeChannel = (socket, channelName) => {
  return (dispatch) => {
    socket.connectChannel(channelName);
    dispatch(Creators.socketSubscribedChannel(channelName));
  };
};

export {Types, Creators};
