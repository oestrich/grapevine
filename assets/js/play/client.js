import {Socket} from "phoenix";
import Sizzle from "sizzle"
import _ from "underscore"
import AnsiUp from 'ansi_up';

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

const ansi_up = new AnsiUp();

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
        this.appendMessage("\u001b[33mConnecting...\n\u001b[0m");
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

  scrollToBottom(panelSelector, callback) {
    let panel = _.first(Sizzle(panelSelector));

    let visibleBottom = panel.scrollTop + panel.clientHeight;
    let triggerScroll = !(visibleBottom + 250 < panel.scrollHeight);

    if (callback != undefined) {
      callback();
    }

    if (triggerScroll) {
      panel.scrollTop = panel.scrollHeight;
    }
  }

  sendMessage() {
    let terminalPrompt = _.first(Sizzle("#prompt"));

    if (terminalPrompt.value == "") {
      this.channel.push("send", {message: "\n"});
    } else {
      this.channel.push("send", {message: terminalPrompt.value});
      terminalPrompt.value = "";
    }
  }

  appendMessage(message) {
    var fragment = document.createDocumentFragment();
    let html = document.createElement("span");
    html.innerHTML = ansi_up.ansi_to_html(message);
    fragment.appendChild(html);

    this.scrollToBottom(".terminal", () => {
      this.terminalElement.appendChild(fragment);
    });
  }
}

export {ClientSocket}
