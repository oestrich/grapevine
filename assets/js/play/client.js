import {Socket} from "phoenix";
import Sizzle from "sizzle"
import _ from "underscore"

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

class ClientSocket {
  join() {
    this.socket = new Socket("/websocket", {params: {token: userToken}})
    this.socket.connect()

    this.connect();
    this.connectSend();
  }

  connect() {
    this.terminalElement = _.first(Sizzle(".terminal"));

    this.channel = this.socket.channel(`play:client`, {game: "DevGame"});

    this.channel.on("echo", (data) => {
      this.appendMessage(data.message);
    })

    this.channel.join()
      .receive("ok", () => {
        this.appendMessage("Connected");
      });
  }

  connectSend() {
    let chatPrompt = _.first(Sizzle("#prompt"));

    chatPrompt.addEventListener("keypress", e => {
      if (e.keyCode == 13) {
        this.sendMessage();
      }
    })

    let send = _.first(Sizzle("#send"));
    send.addEventListener("click", e => {
      this.sendMessage();
    });
  }

  sendMessage() {
    let terminalPrompt = _.first(Sizzle("#prompt"));

    if (terminalPrompt.value != "") {
      this.channel.push("send", {message: terminalPrompt.value});
      terminalPrompt.value = "";
    }
  }

  appendMessage(message) {
    var fragment = document.createDocumentFragment();
    let html = document.createElement("div");
    html.innerHTML = message;
    fragment.appendChild(html);

    this.terminalElement.appendChild(fragment);
  }
}

export {ClientSocket}
