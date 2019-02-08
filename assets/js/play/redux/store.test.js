import {promptClear} from "./store";

describe("actions", () => {
  test("generates a clear prompt action", () => {
    expect(promptClear()).toEqual({type: "PROMPT_CLEAR"});
  });
});
