import {promptReducer} from "./promptReducer";
import {Creators} from "./actions";

describe("set active channel", () => {
  test("updates state", () => {
    let state = {};

    state = promptReducer(state, Creators.promptSetActiveChannel("gossip"));

    expect(state).toEqual({activeChannel: "gossip"});
  });
});

describe("set message", () => {
  test("updates the state for the current message", () => {
    let state = {message: "hello"};

    state = promptReducer(state, Creators.promptSetMessage("hello"));

    expect(state).toEqual({message: "hello"});
  });

  test("set the active channel from typing in the prompt", () => {
    let state = {message: "hello", channels: ["gossip"]};

    state = promptReducer(state, Creators.promptSetMessage("/gossip "));

    expect(state).toEqual({message: "", channels: ["gossip"], activeChannel: "gossip"});
  });

  test("ignores a slash command if it doesn't match a channel", () => {
    let state = {message: "hello", channels: ["gossip"]};

    state = promptReducer(state, Creators.promptSetMessage("/testing "));

    expect(state).toEqual({message: "/testing ", channels: ["gossip"]});
  });
});

describe("subscribe to a channel", () => {
  test("first channel sets the active channel", () => {
    let state = {channels: [], activeChannel: null};

    state = promptReducer(state, Creators.socketSubscribeChannel("gossip"));

    expect(state).toEqual({channels: ["gossip"], activeChannel: "gossip"});
  });

  test("appends to the list of known channels", () => {
    let state = {channels: ["gossip"], activeChannel: "gossip"};

    state = promptReducer(state, Creators.socketSubscribeChannel("testing"));

    expect(state).toEqual({channels: ["gossip", "testing"], activeChannel: "gossip"});
  });
});
