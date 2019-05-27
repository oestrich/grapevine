import {parse} from "./colorizer";
import {Line, ParseError, EscapeSequence} from "./colorizer/models";

describe("combining new text with the last line", () => {
  test("no initial sequence to merge with", () => {
    let sequences = parse(null, ", world");

    expect(sequences).toEqual([
      new Line([
        new EscapeSequence(", world", {id: 0}),
      ])
    ]);
  });

  test("append straight to the text", () => {
    let sequence = new EscapeSequence("Hello", {color: "yellow"});
    let line = new Line([sequence]);

    let sequences = parse(line, ", world");

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

    [line] = parse(line, "[");
    [line] = parse(line, "3");
    [line] = parse(line, "3");
    [line] = parse(line, "m");

    let [sequence] = line.sequences;
    expect(sequence.color).toEqual("yellow");

    [line] = parse(line, "hello");

    [sequence] = line.sequences;
    expect(sequence.color).toEqual("yellow");
    expect(sequence.text).toEqual("hello");
  });

  test("combines multiple sequences", () => {
    let line = new Line([new EscapeSequence("Hello", {color: "yellow"})]);

    [line] = parse(line, "\u001b[");
    [line] = parse(line, "1m");

    let [sequence, sequence2] = line.sequences;
    expect(sequence2.color).toEqual("yellow");
    expect(sequence2.decorations).toEqual(["bold"]);
  });
});

describe("sample real game output", () => {
  test("darkwind", () => {
    let sequences = parse(null, "\u001b[37m\u001b[42m\u001b[5mWGK");

    expect(sequences).toEqual([
      new Line([{id: 0, color: "white", backgroundColor: "green", decorations: [], text: "WGK"}]),
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
      let lines = parse(line, input);
      line = lines.pop();
    });

    expect(line.sequences).toEqual([
      {id: 0, color: "yellow", decorations: [], text: "Yellow "},
      {id: 1, color: "yellow", decorations: ["bold"], text: "bold"},
      {id: 2, color: "yellow", decorations: [], text: " "},
      {id: 3, color: "yellow", decorations: ["underline"], text: "underline "},
      {id: 4, color: "yellow", decorations: ["underline"], text: "reverse"},
      {id: 5, decorations: [], text: ""},
    ]);
  });

  test("lumen et umbra", () => {
    let sequences = parse(null, "\u001B[0;40;1;32m \\");

    expect(sequences).toEqual([
      new Line([{id: 0, color: "green", backgroundColor: "black", decorations: ["bold"], text: " \\"}]),
    ]);
  });

  test("realms of despair", () => {
    let line = `Press [ENTER] \u001b[0m\u001b[2J\n\u001b[u\u001b[s`;
    let lines = parse(null, line);

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
