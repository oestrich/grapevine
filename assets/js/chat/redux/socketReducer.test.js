import {SocketCreators, INITIAL_STATE, socketReducer} from "./socketReducer";

describe("socket connected", () => {
  test("sets to connected", () => {
    let state = socketReducer(INITIAL_STATE, SocketCreators.socketConnected());

    expect(state.connected).toEqual(true);
  });

  test("adds a new connected system message", () => {
    let state = socketReducer(INITIAL_STATE, SocketCreators.socketConnected());

    expect(state.messages).toEqual([{type: "system", color: "green", text: "Connected"}]);
  });
});

describe("socket disconnected", () => {
  test("sets to disconnected", () => {
    let state = Object.assign(INITIAL_STATE, {connected: true});

    state = socketReducer(state, SocketCreators.socketDisconnected());

    expect(state.connected).toEqual(false);
  });

  test("adds a new connected system message", () => {
    let state = Object.assign(INITIAL_STATE, {connected: true});

    state = socketReducer(state, SocketCreators.socketDisconnected());

    expect(state.messages).toEqual([{type: "system", color: "red", text: "Disconnected"}]);
  });

  test("does nothing if already disconnected", () => {
    let state = Object.assign(INITIAL_STATE, {connected: false});

    state = socketReducer(state, SocketCreators.socketDisconnected());

    expect(state.connected).toEqual(false);
    expect(state.messages).toEqual([]);
  });
});

describe("new broadcast message", () => {
  test("appends to the list of known channels", () => {
    let state = socketReducer(INITIAL_STATE, SocketCreators.socketReceiveBroadcast({message: "hello"}));

    expect(state.messages).toEqual([{message: "hello", type: "broadcast"}]);
  });
});

describe("subscribe to a channel", () => {
  test("appends to the list of known channels", () => {
    let state = socketReducer(INITIAL_STATE, SocketCreators.socketSubscribedChannel("gossip"));

    expect(state.channels).toEqual(["gossip"]);
  });
});
