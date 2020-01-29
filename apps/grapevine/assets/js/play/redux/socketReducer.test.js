import {socketReducer} from "./socketReducer";
import {Creators} from "./actions";
import {Line} from "@grapevine/ansi/dist/models";

describe("socket reducer", () => {
  test("socket connected", () => {
    let state = {lines: [], connected: false};

    state = socketReducer(state, Creators.socketConnected());

    expect(state.lines.length).toEqual(1);
    expect(state.connected).toEqual(true);
  });

  test("socket disconnected", () => {
    let state = {lines: [], connected: true};

    state = socketReducer(state, Creators.socketDisconnected());

    expect(state.lines.length).toEqual(0);
    expect(state.connected).toEqual(false);
  });

  test("socket echo", () => {
    let state = {buffer: "Hello\n"};

    state = socketReducer(state, Creators.socketEcho("World"));

    expect(state.buffer).toEqual("Hello\nWorld");
  });

  test("socket input", () => {
    let state = {lines: [], lineId: 0};

    state = socketReducer(state, Creators.socketInput("World"));

    expect(state.lastLine.sequences).toEqual([
      {id: 0, color: "white", backgroundColor: "black", decorations: [], opts: {}, text: "World"},
    ]);
  });

  test("socket go ahead", () => {
    let state = {buffer: "Hello\n", lines: []};

    state = socketReducer(state, Creators.socketGA());

    expect(state.buffer).toEqual("");
    expect(state.lines.length).toEqual(1);
  });

  test("socket receive message", () => {
    let state = {gmcp: {}};

    state = socketReducer(state, Creators.socketReceiveGMCP("Character.Vitals", {hp: 10}));

    expect(state.gmcp).toEqual({"Character.Vitals": {hp: 10}});
  });

  test("socket receive option", () => {
    let state = {options: {}};

    state = socketReducer(state, Creators.socketReceiveOption({key: "prompt_type", value: "password"}));

    expect(state.options).toEqual({"promptType": "password"});
  });

  test("socket receive connection information", () => {
    let state = {connection: {}};

    state = socketReducer(state, Creators.socketReceiveConnection({type: "telnet", host: "localhost", port: 5555}));

    expect(state.connection).toEqual({type: "telnet", host: "localhost", port: 5555});
  });
});
