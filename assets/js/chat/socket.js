import {Socket} from "phoenix";
import Sizzle from "sizzle";
import _ from "underscore";

import {Creators} from "./redux/actions";

class ClientSocket {
  constructor(store, userToken) {
    this.channels = {};
    this.store = store;
    this.userToken = userToken;
  }

  connected()  {
    this.store.dispatch(Creators.socketConnected());
  }

  disconnected() {
    this.store.dispatch(Creators.socketDisconnected());
  }

  receiveBroadcast(data) {
    this.store.dispatch(Creators.socketReceiveBroadcast(data));
  }

  join() {
    this.socket = new Socket("/websocket", {params: {token: this.userToken}});
    this.socket.onOpen(() => {
      this.connected();
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
