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
    this.channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) });

    this.channel.on("messages/broadcast", data => {
      let message = `<span class="blue">${data.name}@${data.game}</span> says, <span class="green">"${data.message}"</span><br/>`;

      let fragment = document.createDocumentFragment();
      let span = document.createElement('span');
      span.innerHTML = message;
      fragment.appendChild(span);

      this.channelElement.appendChild(fragment);
    });
  }
}
