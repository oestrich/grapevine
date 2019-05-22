import LiveSocket from "phoenix_live_view";

if (document.querySelector("[data-live=true]")) {
  let liveSocket = new LiveSocket("/live");
  liveSocket.connect();
}
