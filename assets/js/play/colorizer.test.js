import {
  Line,
  EscapeSequence,
  ParseError,
  segmentEscapes,
  parseEscapeSequence,
  combineAndParseSegments,
  combineAndParse,
  detectLines,
} from "./colorizer";

describe("processes text for color codes", () => {
  test("simple escape codes", () => {
    expect(segmentEscapes("\u001b[33mHello\u001b[0m")).toEqual([
      {text: ""},
      {color: "yellow", text: "Hello"},
      {text: ""},
    ]);

    expect(segmentEscapes("Hello, \u001b[33mWorld\u001b[0m")).toEqual([
      {text: "Hello, "},
      {color: "yellow", text: "World"},
      {text: ""},
    ]);
  });

  test("with bold", () => {
    expect(segmentEscapes("Hello, \u001b[1;33mWorld\u001b[0m")).toEqual([
      {text: "Hello, "},
      {color: "yellow", decoration: "bold", text: "World"},
      {text: ""},
    ]);
  });

  test("parse error in middle", () => {
    expect(segmentEscapes("Hello, \u001b[33Lost\u001b[33mHow are you?")).toEqual([
      {text: "Hello, "},
      {sequence: "\u001b[33Lost"},
      {color: "yellow", text: "How are you?"}
    ]);
  });

  test("trailing parse error", () => {
    expect(segmentEscapes("Hello, \u001b[33")).toEqual([
      {text: "Hello, "},
      {sequence: "\u001b[33"}
    ]);
  });
});

describe("determining an escape code", () => {
  test("basic color codes", () => {
    expect(parseEscapeSequence("\u001b[30mHello")).toEqual({color: "black", text: "Hello"});
    expect(parseEscapeSequence("\u001b[31mHello")).toEqual({color: "red", text: "Hello"});
    expect(parseEscapeSequence("\u001b[32mHello")).toEqual({color: "green", text: "Hello"});
    expect(parseEscapeSequence("\u001b[33mHello")).toEqual({color: "yellow", text: "Hello"});
    expect(parseEscapeSequence("\u001b[34mHello")).toEqual({color: "blue", text: "Hello"});
    expect(parseEscapeSequence("\u001b[35mHello")).toEqual({color: "magenta", text: "Hello"});
    expect(parseEscapeSequence("\u001b[36mHello")).toEqual({color: "cyan", text: "Hello"});
    expect(parseEscapeSequence("\u001b[37mHello")).toEqual({color: "white", text: "Hello"});
  });

  test("basic background color codes", () => {
    expect(parseEscapeSequence("\u001b[40mHello")).toEqual({backgroundColor: "black", text: "Hello"});
    expect(parseEscapeSequence("\u001b[41mHello")).toEqual({backgroundColor: "red", text: "Hello"});
    expect(parseEscapeSequence("\u001b[42mHello")).toEqual({backgroundColor: "green", text: "Hello"});
    expect(parseEscapeSequence("\u001b[43mHello")).toEqual({backgroundColor: "yellow", text: "Hello"});
    expect(parseEscapeSequence("\u001b[44mHello")).toEqual({backgroundColor: "blue", text: "Hello"});
    expect(parseEscapeSequence("\u001b[45mHello")).toEqual({backgroundColor: "magenta", text: "Hello"});
    expect(parseEscapeSequence("\u001b[46mHello")).toEqual({backgroundColor: "cyan", text: "Hello"});
    expect(parseEscapeSequence("\u001b[47mHello")).toEqual({backgroundColor: "white", text: "Hello"});
  });

  test("bright color codes", () => {
    expect(parseEscapeSequence("\u001b[90mHello")).toEqual({color: "black", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[91mHello")).toEqual({color: "red", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[92mHello")).toEqual({color: "green", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[93mHello")).toEqual({color: "yellow", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[94mHello")).toEqual({color: "blue", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[95mHello")).toEqual({color: "magenta", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[96mHello")).toEqual({color: "cyan", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[97mHello")).toEqual({color: "white", decoration: "bright", text: "Hello"});
  });

  test("bright background color codes", () => {
    expect(parseEscapeSequence("\u001b[100mHello")).toEqual({backgroundColor: "black", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[101mHello")).toEqual({backgroundColor: "red", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[102mHello")).toEqual({backgroundColor: "green", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[103mHello")).toEqual({backgroundColor: "yellow", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[104mHello")).toEqual({backgroundColor: "blue", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[105mHello")).toEqual({backgroundColor: "magenta", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[106mHello")).toEqual({backgroundColor: "cyan", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[107mHello")).toEqual({backgroundColor: "white", decoration: "bright", text: "Hello"});
  });

  test("parse 256 color codes", () => {
    expect(parseEscapeSequence("\u001b[38;5;3mHello")).toEqual({color: "yellow", text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;5;11mHello")).toEqual({color: "yellow", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;5;226mHello")).toEqual({color: "#ffff00", text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;5;243mHello")).toEqual({color: "#767676", text: "Hello"});
  });

  test("parse 256 background color codes", () => {
    expect(parseEscapeSequence("\u001b[48;5;3mHello")).toEqual({backgroundColor: "yellow", text: "Hello"});
    expect(parseEscapeSequence("\u001b[48;5;11mHello")).toEqual({backgroundColor: "yellow", decoration: "bright", text: "Hello"});
    expect(parseEscapeSequence("\u001b[48;5;226mHello")).toEqual({backgroundColor: "#ffff00", text: "Hello"});
    expect(parseEscapeSequence("\u001b[48;5;243mHello")).toEqual({backgroundColor: "#767676", text: "Hello"});
  });

  test("parse true color color codes", () => {
    expect(parseEscapeSequence("\u001b[38;2;3;3;3mHello")).toEqual({color: "#030303", text: "Hello"});
    expect(parseEscapeSequence("\u001b[38;2;0;255;0mHello")).toEqual({color: "#00ff00", text: "Hello"});
  });

  test("decoration options", () => {
    expect(parseEscapeSequence("\u001b[1;33mHello")).toEqual({color: "yellow", decoration: "bold", text: "Hello"});
    expect(parseEscapeSequence("\u001b[33;1mHello")).toEqual({color: "yellow", decoration: "bold", text: "Hello"});
  });
});

describe("combining new text with the last parsed segment", () => {
  test("no initial sequence to merge with", () => {
    let sequences = combineAndParseSegments(null, ", world");

    expect(sequences).toEqual([{text: ", world"}]);
  });

  test("append straight to the text", () => {
    let sequence = new EscapeSequence("Hello", {color: "yellow"});

    let sequences = combineAndParseSegments(sequence, ", world");

    expect(sequences).toEqual([{color: "yellow", text: "Hello, world"}]);
  });

  test("changing colors", () => {
    let sequence = new EscapeSequence("Hello");

    let sequences = combineAndParseSegments(sequence, ", \u001b[33mworld");

    expect(sequences).toEqual([{text: "Hello, "}, {color: "yellow", text: "world"}]);
  });

  test("appending to a parse error and converting to a proper sequence", () => {
    let sequence = new ParseError("\u001b[33");

    let sequences = combineAndParseSegments(sequence, "mworld");

    expect(sequences).toEqual([{color: "yellow", text: "world"}]);
  });

  test("new text includes a parse error that is trying to merge", () => {
    let sequence = new EscapeSequence("Hello");

    let sequences = combineAndParseSegments(sequence, "\u001b[33");

    expect(sequences).toEqual([{text: "Hello"}, {sequence: "\u001b[33"}]);
  });
});

describe("combining new text with the last line", () => {
  test("no initial sequence to merge with", () => {
    let sequences = combineAndParse(null, ", world");

    expect(sequences).toEqual([
      new Line([
        new EscapeSequence(", world", {id: 0}),
      ])
    ]);
  });

  test("append straight to the text", () => {
    let sequence = new EscapeSequence("Hello", {color: "yellow"});
    let line = new Line([sequence]);

    let sequences = combineAndParse(line, ", world");

    expect(sequences).toEqual([
      new Line([
        new EscapeSequence("Hello, world", {id: 0, color: "yellow"}),
      ])
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
