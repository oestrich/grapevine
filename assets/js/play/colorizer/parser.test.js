import {Line, EscapeSequence, ParseError} from "./models";

import {
  splitByEscapeSequence,
  parseEscapeSequence,
  parseSequences,
  detectLines,
} from "./parser";

describe("processes text for color codes", () => {
  test("simple escape codes", () => {
    expect(splitByEscapeSequence("\u001b[33mHello\u001b[0m", {})).toEqual([
      {text: ""},
      {color: "yellow", decorations: [], text: "Hello"},
      {decorations: [], text: ""},
    ]);

    expect(splitByEscapeSequence("Hello, \u001b[33mWorld\u001b[0m", {})).toEqual([
      {text: "Hello, "},
      {color: "yellow", decorations: [], text: "World"},
      {decorations: [], text: ""},
    ]);
  });

  test("with bold", () => {
    expect(splitByEscapeSequence("Hello, \u001b[1;33mWorld\u001b[0m", {})).toEqual([
      {text: "Hello, "},
      {color: "yellow", decorations: ["bold"], text: "World"},
      {decorations: [], text: ""},
    ]);
  });

  test("parse error in middle", () => {
    expect(splitByEscapeSequence("Hello, \u001b[33Lost\u001b[33mHow are you?", {})).toEqual([
      {text: "Hello, "},
      {sequence: "\u001b[33Lost"},
      {color: "yellow", decorations: [], text: "How are you?"}
    ]);
  });

  test("trailing parse error", () => {
    expect(splitByEscapeSequence("Hello, \u001b[33")).toEqual([
      {text: "Hello, "},
      {sequence: "\u001b[33"}
    ]);
  });
});

describe("determining an escape code", () => {
  test("basic color codes", () => {
    expect(parseEscapeSequence("\u001b[30mHello", {})).toEqual({color: "black", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[31mHello", {})).toEqual({color: "red", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[32mHello", {})).toEqual({color: "green", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[33mHello", {})).toEqual({color: "yellow", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[34mHello", {})).toEqual({color: "blue", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[35mHello", {})).toEqual({color: "magenta", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[36mHello", {})).toEqual({color: "cyan", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[37mHello", {})).toEqual({color: "white", decorations: [], text: "Hello"});
  });

  test("basic background color codes", () => {
    expect(parseEscapeSequence("\u001b[40mHello", {})).toEqual({backgroundColor: "black", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[41mHello", {})).toEqual({backgroundColor: "red", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[42mHello", {})).toEqual({backgroundColor: "green", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[43mHello", {})).toEqual({backgroundColor: "yellow", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[44mHello", {})).toEqual({backgroundColor: "blue", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[45mHello", {})).toEqual({backgroundColor: "magenta", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[46mHello", {})).toEqual({backgroundColor: "cyan", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[47mHello", {})).toEqual({backgroundColor: "white", decorations: [], text: "Hello"});
  });

  test("bright color codes", () => {
    expect(parseEscapeSequence("\u001b[90mHello", {})).toEqual({color: "black", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[91mHello", {})).toEqual({color: "red", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[92mHello", {})).toEqual({color: "green", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[93mHello", {})).toEqual({color: "yellow", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[94mHello", {})).toEqual({color: "blue", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[95mHello", {})).toEqual({color: "magenta", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[96mHello", {})).toEqual({color: "cyan", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[97mHello", {})).toEqual({color: "white", decorations: ["bright"], text: "Hello"});
  });

  test("bright background color codes", () => {
    expect(parseEscapeSequence("\u001b[100mHello", {})).toEqual({backgroundColor: "black", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[101mHello", {})).toEqual({backgroundColor: "red", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[102mHello", {})).toEqual({backgroundColor: "green", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[103mHello", {})).toEqual({backgroundColor: "yellow", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[104mHello", {})).toEqual({backgroundColor: "blue", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[105mHello", {})).toEqual({backgroundColor: "magenta", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[106mHello", {})).toEqual({backgroundColor: "cyan", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[107mHello", {})).toEqual({backgroundColor: "white", decorations: ["bright"], text: "Hello"});
  });

  test("parse 256 color codes", () => {
    expect(parseEscapeSequence("\u001b[38;5;3mHello", {})).toEqual({color: "yellow", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;5;11mHello", {})).toEqual({color: "yellow", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;5;226mHello", {})).toEqual({color: "#ffff00", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;5;243mHello", {})).toEqual({color: "#767676", decorations: [], text: "Hello"});
  });

  test("parse 256 background color codes", () => {
    expect(parseEscapeSequence("\u001b[48;5;3mHello", {})).toEqual({backgroundColor: "yellow", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[48;5;11mHello", {})).toEqual({backgroundColor: "yellow", decorations: ["bright"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[48;5;226mHello", {})).toEqual({backgroundColor: "#ffff00", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[48;5;243mHello", {})).toEqual({backgroundColor: "#767676", decorations: [], text: "Hello"});
  });

  test("parse true color color codes", () => {
    expect(parseEscapeSequence("\u001b[38;2;3;3;3mHello", {})).toEqual({color: "#030303", decorations: [], text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;2;0;255;0mHello", {})).toEqual({color: "#00ff00", decorations: [], text: "Hello"});
  });

  test("decoration options", () => {
    expect(parseEscapeSequence("\u001b[1;33mHello", {})).toEqual({color: "yellow", decorations: ["bold"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[4mHello", {})).toEqual({decorations: ["underline"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[33;1mHello", {})).toEqual({color: "yellow", decorations: ["bold"], text: "Hello"});
    expect(parseEscapeSequence("\u001b[93;1mHello", {})).toEqual({color: "yellow", decorations: ["bold", "bright"], text: "Hello"});
  });

  test("blinking", () => {
    expect(parseEscapeSequence("\u001b[5m", {})).toEqual({decorations: ["blink"], text: ""});
    expect(parseEscapeSequence("\u001b[6m", {})).toEqual({decorations: ["blink"], text: ""});
  });

  test("reverse video", () => {
    expect(parseEscapeSequence("\u001b[7m", {color: "white", backgroundColor: "green"})).
      toEqual({color: "green", backgroundColor: "white", decorations: [], text: ""});
  });
});

describe("combining new text with the last parsed splitByEscapeSequence", () => {
  test("no initial sequence to merge with", () => {
    let sequences = parseSequences([], ", world");

    expect(sequences).toEqual([{text: ", world"}]);
  });

  test("append straight to the text", () => {
    let sequence = new EscapeSequence("Hello", {color: "yellow"});

    let sequences = parseSequences([sequence], ", world");

    expect(sequences).toEqual([
      {color: "yellow", text: "Hello, world"}
    ]);
  });

  test("changing colors", () => {
    let sequence = new EscapeSequence("Hello");

    let sequences = parseSequences([sequence], ", \u001b[33mworld");

    expect(sequences).toEqual([
      {text: "Hello, "},
      {color: "yellow", decorations: [], text: "world"}
    ]);
  });

  test("changing bold status", () => {
    let sequence = new EscapeSequence("Hello", {color: "yellow"});

    let sequences = parseSequences([sequence], ", \u001b[1mworld");

    expect(sequences).toEqual([
      {color: "yellow", text: "Hello, "},
      {color: "yellow", decorations: ["bold"], text: "world"}
    ]);
  });

  test("appending to a parse error and converting to a proper sequence", () => {
    let sequence = new ParseError("\u001b[33");

    let sequences = parseSequences([sequence], "mworld");

    expect(sequences).toEqual([
      {text: ""},
      {color: "yellow", decorations: [], text: "world"}
    ]);
  });

  test("new text includes a parse error that is trying to merge", () => {
    let sequence = new EscapeSequence("Hello");

    let sequences = parseSequences([sequence], "\u001b[33");

    expect(sequences).toEqual([
      {text: "Hello"},
      {sequence: "\u001b[33"}
    ]);
  });
});

describe("create lines from sequences", () => {
  test("batches by newlines", () => {
    let sequences = [
      new EscapeSequence("Hello", {color: "yellow"}),
      new EscapeSequence(", world!", {color: "green"}),
      new EscapeSequence("\n How are you?"),
    ];

    let lines = detectLines(sequences);

    expect(lines).toEqual([
      new Line([
        new EscapeSequence("Hello", {id: 0, color: "yellow"}),
        new EscapeSequence(", world!", {id: 1, color: "green"}),
        new EscapeSequence("\n", {id: 2}),
      ]),
      new Line([
        new EscapeSequence(" How are you?", {id: 0}),
      ]),
    ]);
  });

  test("handles parse errors", () => {
    let sequences = [
      new EscapeSequence("Hello", {color: "yellow"}),
      new EscapeSequence(", world!", {color: "green"}),
      new ParseError("\u001b[33"),
    ];

    let lines = detectLines(sequences);

    expect(lines).toEqual([
      new Line([
        new EscapeSequence("Hello", {id: 0, color: "yellow"}),
        new EscapeSequence(", world!", {id: 1, color: "green"}),
        new ParseError("\u001b[33", {id: 2}),
      ]),
    ]);
  });
});
