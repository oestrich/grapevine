import {Socket} from "phoenix";
import Sizzle from "sizzle";
import _ from "underscore";

import {SocketCreators} from "./redux/socketReducer";

const MAX_RETRIES = 50;

class ClientSocket {
  constructor(store, userToken) {
    this.channels = {};
    this.store = store;
    this.userToken = userToken;
    this.retryCount = 0;
  }

  connected()  {
    this.store.dispatch(SocketCreators.socketConnected());
  }

  disconnected() {
    this.store.dispatch(SocketCreators.socketDisconnected());
  }

  receiveBroadcast(data) {
    this.store.dispatch(SocketCreators.socketReceiveBroadcast(data));
  }

  join() {
    this.socket = new Socket("/websocket", {params: {token: this.userToken}});

    this.socket.onOpen(() => {
      this.retryCount = 0;
      this.connected();
    });

    this.socket.onError(() => {
      this.retryCount += 1;

      if (this.retryCount > MAX_RETRIES) {
        this.socket.disconnect();
      }
    });

    this.socket.onClose(() => {
      this.disconnected();
    });

    this.socket.connect();

    return this;
  }

  connectChannel(channelName) {
    const channel = this.socket.channel(`chat:${channelName}`, {});
    channel.on("broadcast", (data) => {
      this.receiveBroadcast(data);
    });
    channel.join();
    this.channels[channelName] = channel;
  }

  send(channelName, message) {
    const channel = this.channels[channelName];

    if (channel) {
      channel.push("send", {message: message});
    }
  }
}

export {ClientSocket};
