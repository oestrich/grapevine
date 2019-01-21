import {Socket} from "phoenix"

let guid = () => {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
};

var body = document.getElementById("body")
var userToken = body.getAttribute("data-user-token")

export default class MSSPSocket {
  constructor(responseSelector) {
    this.responseSelector = responseSelector;
    this.responseElement = document.querySelector(responseSelector);
  }

  connect() {
    this.socket = new Socket("/chat", {params: {token: userToken}})
    this.socket.connect();

    this.channel = this.socket.channel(`mssp:${guid()}`, {});
    this.channel.join().
      receive("ok", resp => { console.log("Connected") });

    this.channel.on("mssp/terminated", data => {
      this.append("Did not find MSSP data");
    });

    this.channel.on("mssp/received", data => {
      let json = JSON.stringify(data, null, 2);
      this.append("Received MSSP:");
      this.append(json);
    });
  }

  checkHost(host, port) {
    this.reset();
    this.append(`Checking ${host}:${port}`);
    this.channel.push("check", {host, port});
  }

  reset() {
    this.responseElement.innerHTML = "";
  }

  append(message) {
    let fragment = document.createDocumentFragment();
    let span = document.createElement('span');
    span.innerHTML = message + "\n";
    fragment.appendChild(span);

    this.responseElement.appendChild(fragment);
  }
}
