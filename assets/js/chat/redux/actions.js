import {createActions} from 'reduxsauce';

const {Types, Creators} = createActions({
  promptSetMessage: ["message"],
  promptSetActiveChannel: ["channel"],
  socketConnected: null,
  socketDisconnected: null,
  socketReceiveBroadcast: ["message"],
  socketSubscribeChannel: ["channel"],
});

Creators.socketSubscribeChannel = (socket, channelName) => {
  return (dispatch) => {
    socket.connectChannel(channelName);

    return dispatch({
      type: Types.SOCKET_SUBSCRIBE_CHANNEL,
      channel: channelName,
    });
  };
};

export {Types, Creators};
