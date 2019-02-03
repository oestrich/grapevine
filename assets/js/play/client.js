import {Socket} from "phoenix";
import Sizzle from "sizzle"
import _ from "underscore"
import AnsiUp from 'ansi_up';

import {ClientSocket} from "./socket";
import Keys from './keys';

let body = document.getElementById("body");
let userToken = body.getAttribute("data-user-token");

const ansi_up = new AnsiUp();

class Client {
  constructor(game) {
    this.game = game;
  }

  join() {
    this.socket = new ClientSocket(this, this.game, userToken);
    this.socket.join();
    this.connectSend();

    this.keys = new Keys();

    document.addEventListener('keydown', e => {
      if (!this.keys.isModifierKeyPressed()) {
        document.getElementById('prompt').focus();
      }
    });
  }

  connectSend() {
    this.terminalElement = _.first(Sizzle(".terminal"));
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
      this.socket.send("\n");
    } else {
      this.socket.send(`${terminalPrompt.value}\n`);
      terminalPrompt.value = "";
    }
  }

  appendText(message) {
    var fragment = document.createDocumentFragment();
    let html = document.createElement("span");
    html.innerHTML = ansi_up.ansi_to_html(message);
    fragment.appendChild(html);

    this.scrollToBottom(".terminal", () => {
      this.terminalElement.appendChild(fragment);
    });
  }
}

export {Client}
