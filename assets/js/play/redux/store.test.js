import {promptClear} from "./store";

test("generates a clear prompt action", () => {
  expect(promptClear()).toEqual({type: "PROMPT_CLEAR"});
});
