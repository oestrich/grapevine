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

    this.connectedChannels = [];
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

  /**
   * Join the web socket
   */
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

  /**
   * Connect to the channel
   *
   * Subscribes and replays past messages
   */
  connectChannel(channelName) {
    const channel = this.socket.channel(`chat:${channelName}`, {});
    channel.on("broadcast", (data) => {
      this.receiveBroadcast(data);
    });

    channel.join().
      receive("ok", (data) => {
        this.channelConnected(channelName, data.messages);
      });

    this.channels[channelName] = channel;
  }

  /**
   * Send a message to a channel if it exists
   */
  send(channelName, message) {
    const channel = this.channels[channelName];

    if (channel) {
      channel.push("send", {message: message});
    }
  }

  channelConnected(channel, messages) {
    messages = messages.map((message) => {
      message.channel = channel;
      return message;
    });

    this.connectedChannels.push({channel, messages});
    this.checkAllChannelsSubscribed();
  }

  channelsConnected(channelCount) {
    this.channelCount = channelCount;
    this.checkAllChannelsSubscribed();
  }

  checkAllChannelsSubscribed() {
    if (!this.channelCount) { return; }

    if (this.channelCount == this.connectedChannels.length) {
      let messages = this.connectedChannels.flatMap(({messages}) => { return messages; });
      messages.sort((a, b) => (a.inserted_at > b.inserted_at) ? 1 : -1)
      messages.slice(0, 30).forEach((message) => {
        this.receiveBroadcast(message);
      });
    }
  }
}

export {ClientSocket};
