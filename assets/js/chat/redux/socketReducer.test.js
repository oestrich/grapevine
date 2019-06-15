import {INITIAL_STATE, socketReducer} from "./socketReducer";
import {Creators, Types} from "./actions";

describe("socket connected", () => {
  test("sets to connected", () => {
    let state = socketReducer(INITIAL_STATE, Creators.socketConnected());

    expect(state.connected).toEqual(true);
  });

  test("adds a new connected system message", () => {
    let state = socketReducer(INITIAL_STATE, Creators.socketConnected());

    expect(state.messages).toEqual([{type: "system", color: "green", text: "Connected"}]);
  });
});

describe("socket disconnected", () => {
  test("sets to disconnected", () => {
    let state = Object.assign(INITIAL_STATE, {connected: true});

    state = socketReducer(state, Creators.socketDisconnected());

    expect(state.connected).toEqual(false);
  });

  test("adds a new connected system message", () => {
    let state = Object.assign(INITIAL_STATE, {connected: true});

    state = socketReducer(state, Creators.socketDisconnected());

    expect(state.messages).toEqual([{type: "system", color: "red", text: "Disconnected"}]);
  });

  test("does nothing if already disconnected", () => {
    let state = Object.assign(INITIAL_STATE, {connected: false});

    state = socketReducer(state, Creators.socketDisconnected());

    expect(state.connected).toEqual(false);
    expect(state.messages).toEqual([]);
  });
});

describe("new broadcast message", () => {
  test("appends to the list of known channels", () => {
    let state = socketReducer(INITIAL_STATE, Creators.socketReceiveBroadcast({message: "hello"}));

    expect(state.messages).toEqual([{message: "hello", type: "broadcast"}]);
  });
});

describe("subscribe to a channel", () => {
  test("appends to the list of known channels", () => {
    let state = socketReducer(INITIAL_STATE, {type: Types.SOCKET_SUBSCRIBE_CHANNEL, channel: "gossip"});

    expect(state.channels).toEqual(["gossip"]);
  });
});
