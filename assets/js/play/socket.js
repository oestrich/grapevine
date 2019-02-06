import {Socket} from "phoenix";
import Sizzle from "sizzle"
import _ from "underscore"

class ClientSocket {
  constructor(client, game, userToken) {
    this.client = client;
    this.game = game;
    this.userToken = userToken;
  }

  join() {
    this.socket = new Socket("/websocket", {params: {token: this.userToken}});
    this.socket.connect();
    this.connect();
  }

  connect() {
    this.channel = this.socket.channel(`play:client`, {game: this.game});

    this.channel.on("echo", (data) => {
      this.client.appendText(data.message);
    });

    this.channel.on("gmcp", (data) => {
      this.client.receiveGMCP(data.module, data.data);
    });

    this.channel.on("ga", () => {
      this.client.processText();
    });

    this.channel.join()
      .receive("ok", () => {
        this.client.appendText("\u001b[33mConnecting...\n\u001b[0m");
      });
  }

  send(message) {
    this.channel.push("send", {message: message});
  }
}

export {ClientSocket};
