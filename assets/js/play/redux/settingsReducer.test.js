import {settingsReducer} from "./settingsReducer";
import {Creators} from "./actions";

describe("settings reducer", () => {
  test("toggles the open state", () => {
    let state = {open: false};

    state = settingsReducer(state, Creators.settingsToggle());

    expect(state).toEqual({open: true});
  });

  test("sets the font", () => {
    let state = {font: "Monaco"};

    state = settingsReducer(state, Creators.settingsSetFont("Source Code Pro"));

    expect(state).toEqual({font: "Source Code Pro"});
  });

  test("sets the font size", () => {
    let state = {fontSize: 16};

    state = settingsReducer(state, Creators.settingsSetFontSize("20"));

    expect(state).toEqual({fontSize: 20});
  });
});
