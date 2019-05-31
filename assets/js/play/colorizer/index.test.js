import {parse, appendInput} from "./index";
import {Line, EscapeSequence, InputSequence, ParseError} from "./models";

describe("combining new text with the last line", () => {
  test("no initial sequence to merge with", () => {
    let sequences = parse(", world");

    expect(sequences).toEqual([
      new Line([
        new EscapeSequence(", world", {id: 0}),
      ])
    ]);
  });

  test("append straight to the text", () => {
    let sequence = new EscapeSequence("Hello", {color: "yellow"});
    let line = new Line([sequence]);

    let sequences = parse(", world", line);

    expect(sequences).toEqual([
      new Line([
        new EscapeSequence("Hello, world", {id: 0, color: "yellow"}),
      ])
    ]);
  });
});

describe("parse errors", () => {
  test("appends properly", () => {
    let lastSequence = new ParseError("\u001b");
    let line = new Line([lastSequence]);

    [line] = parse("[", line);
    [line] = parse("3", line);
    [line] = parse("3", line);
    [line] = parse("m", line);

    let [sequence] = line.sequences;
    expect(sequence.color).toEqual("yellow");

    [line] = parse("hello", line);

    [sequence] = line.sequences;
    expect(sequence.color).toEqual("yellow");
    expect(sequence.text).toEqual("hello");
  });

  test("combines multiple sequences", () => {
    let line = new Line([new EscapeSequence("Hello", {color: "yellow"})]);

    [line] = parse("\u001b[", line);
    [line] = parse("1m", line);

    let [sequence, sequence2] = line.sequences;
    expect(sequence2.color).toEqual("yellow");
    expect(sequence2.decorations).toEqual(["bold"]);
  });
});

describe("appending game input", () => {
  test("appends to the last line and passes the options through", () => {
    let line = new Line([new EscapeSequence("Hello", {color: "yellow"})]);

    [line] = appendInput(line, "hello");

    expect(line.sequences).toEqual([
      {id: 0, color: "yellow", text: "Hello"},
      {id: 1, color: "white", backgroundColor: "black", decorations: [], opts: {color: "yellow"}, text: "hello"},
    ]);
  });
});

describe("sample real game output", () => {
  test("darkwind", () => {
    let sequences = parse("\u001b[37m\u001b[42m\u001b[5mWGK");

    expect(sequences).toEqual([
      new Line([{id: 0, color: "white", backgroundColor: "green", decorations: ["blink"], text: "WGK"}]),
    ]);
  });

  test("last outpost", () => {
    let inputs = [
      "\u001b[33mYell",
      "ow \u001b[1mbold\u001b[0m\u001b[3",
      "3m \u001b[4munderline \u001b[",
      "7mreverse\u001b[0m",
    ];

    let line = null;
    inputs.map((input) => {
      let lines = parse(input, line);
      line = lines.pop();
    });

    expect(line.sequences).toEqual([
      {id: 0, color: "yellow", decorations: [], text: "Yellow "},
      {id: 1, color: "yellow", decorations: ["bold"], text: "bold"},
      {id: 2, color: "yellow", decorations: [], text: " "},
      {id: 3, color: "yellow", decorations: ["underline"], text: "underline "},
      {id: 4, backgroundColor: "yellow", decorations: ["underline"], text: "reverse"},
      {id: 5, decorations: [], text: ""},
    ]);
  });

  test("lumen et umbra", () => {
    let sequences = parse("\u001B[0;40;1;32m \\");

    expect(sequences).toEqual([
      new Line([{id: 0, color: "green", backgroundColor: "black", decorations: ["bold"], text: " \\"}]),
    ]);
  });

  test("realms of despair", () => {
    let line = `Press [ENTER] \u001b[0m\u001b[2J\n\u001b[u\u001b[s`;
    let lines = parse(line);

    expect(lines).toEqual([
      new Line([
        {id: 0, text: "Press [ENTER] "},
        {id: 1, decorations: [], text: "\n"},
      ]),
      new Line([
        {id: 0, decorations: [], text: ""},
      ]),
    ]);
  });
});
