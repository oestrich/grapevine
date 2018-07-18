import {Socket} from "phoenix"

export default class ChatSocket {
  constructor(channelName, channelSelector) {
    this.channelName = channelName;
    this.channelSelector = channelSelector;
    this.channelElement = document.querySelector(channelSelector);
  }

  connect() {
    this.socket = new Socket("/chat");
    this.socket.connect();

    this.channel = this.socket.channel(`channels:${this.channelName}`, {});
    this.channel.join().receive("ok", resp => { this.append("Connected") });

    this.channel.on("channels/broadcast", data => {
      let message = `<span class="blue">${data.name}@${data.game}</span> says, <span class="green">"${data.message}"</span>`;
      this.append(message);
    });
  }

  append(message) {
    let fragment = document.createDocumentFragment();
    let span = document.createElement('span');
    span.innerHTML = message + "<br />";
    fragment.appendChild(span);

    this.channelElement.appendChild(fragment);
    this.channelElement.scrollTop = this.channelElement.scrollHeight;
  }
}
