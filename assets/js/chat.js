import {Socket} from "phoenix"
import Sizzle from "sizzle"
import _ from "underscore"

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

class Channels {
  join() {
    this.socket = new Socket("/websocket", {params: {token: userToken}})
    this.socket.connect()

    this.channels = {};

    _.each(Sizzle(".channel"), (channel) => {
      this.connectChannel(channel);
    });

    this.connectSend();
    this.connectTabHandlers();
  }

  connectChannel(channelEl) {
    let channelName = channelEl.dataset.channel;

    let channel = this.socket.channel(`chat:${channelName}`, {});
    this.channels[channelName] = channel;

    channel.on("broadcast", (data) => {
      this.alertChannel(channelName);

      let message;
      if (data.game == null || data.game == undefined) {
        message = `<span class="blue">${data.name}</span> says, <span class="green">"${data.message}"</span>`;
      } else {
        message = `<span class="blue">${data.name}@${data.game}</span> says, <span class="green">"${data.message}"</span>`;
      }

      this.appendMessage(channelEl, message);
    })

    channel.join()
      .receive("ok", () => {
        this.appendMessage(channelEl, "Connected");
      });
  }

  connectSend() {
    let chatPrompt = _.first(Sizzle("#chat-prompt"));
    chatPrompt.addEventListener("keypress", e => {
      if (e.keyCode == 13) {
        this.sendMessage();
      }
    })

    let send = _.first(Sizzle("#chat-send"));
    send.addEventListener("click", e => {
      this.sendMessage();
    });
  }

  connectTabHandlers() {
    _.each(Sizzle(".channel-tab"), channelTab => {
      channelTab.addEventListener("click", (e) => {
        let bellIcon = _.first(Sizzle(".bell", channelTab));
        bellIcon.classList.add("hidden");
      });
    });
  }

  sendMessage() {
    let chatPrompt = _.first(Sizzle("#chat-prompt"));
    let activeChannel = _.first(Sizzle(".channel.active"));
    let channel = this.channels[activeChannel.dataset.channel];
    if (chatPrompt.value != "") {
      channel.push("send", {message: chatPrompt.value});
      chatPrompt.value = "";
    }
  }

  appendMessage(channelEl, message) {
    var fragment = document.createDocumentFragment();
    let html = document.createElement("div");
    html.innerHTML = message;
    fragment.appendChild(html);

    channelEl.appendChild(fragment);
  }

  alertChannel(channelName) {
    let channelTab = _.first(Sizzle(`.channel-tab[data-channel="${channelName}"]`));
    let activeChannel = _.first(Sizzle(".channel.active"));
    if (activeChannel.dataset.channel != channelName) {
      let bellIcon = _.first(Sizzle(".bell", channelTab));
      bellIcon.classList.remove("hidden");
    }
  }
}

export {Channels}
