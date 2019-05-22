import _ from "underscore";

export class Line {
  constructor(sequences) {
    this.sequences = sequences;
  }

  last() {
    return _.last(this.sequences);
  }
}

export class ParseError {
  constructor(sequence, opts) {
    this.sequence = sequence;

    if (opts && opts.id !== null && opts.id !== undefined) {
      this.id = opts.id;
    }
  }
}

export class EscapeSequence {
  constructor(text, opts) {
    this.text = text;

    if (opts !== null && opts !== undefined) {
      if (opts.id !== null && opts.id !== undefined) {
        this.id = opts.id;
      }

      if (opts.color) {
        this.color = opts.color;
      }

      if (opts.backgroundColor) {
        this.backgroundColor = opts.backgroundColor;
      }

      if (opts.decoration) {
        this.decoration = opts.decoration;
      }
    }
  }
}

const basicColorCodes = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"];

const toHex = (decimal) => {
  let hex = decimal.toString(16);
  if (hex.length < 2) {
    hex = "0" + hex;
  }
  return hex;
};


const rgbToHex = (r, g, b) => {
  return "#" + toHex(r) + toHex(g) + toHex(b);
};

// Mostly from Anser, https://github.com/IonicaBizau/anser
const memoize256Colors = () => {
  window.colorizer256Colors = [];

  // Index 0..15 : System color
  for (let i = 0; i < 16; ++i) {
    window.colorizer256Colors.push(null);
  }

  // Index 16..231 : RGB 6x6x6
  // https://gist.github.com/jasonm23/2868981#file-xterm-256color-yaml
  let levels = [0, 95, 135, 175, 215, 255];
  let r, g, b;
  for (let r = 0; r < 6; ++r) {
    for (let g = 0; g < 6; ++g) {
      for (let b = 0; b < 6; ++b) {
        window.colorizer256Colors.push(rgbToHex(levels[r], levels[g], levels[b]));
      }
    }
  }

  // Index 232..255 : Grayscale
  let level = 8;
  for (let i = 0; i < 24; ++i, level += 10) {
    window.colorizer256Colors.push(rgbToHex(level, level, level));
  }
};

const parse256Color = (color, key) => {
  // memoize colors to the window
  if (window.colorizer256Colors == undefined) {
    memoize256Colors();
  }

  switch (true) {
    case color < 8:
      return {[key]: basicColorCodes[color]};

    case color < 16:
      return {[key]: basicColorCodes[color - 8], decoration: "bright"};

    default:
      return {[key]: colorizer256Colors[color]};
  }
};

export const parseEscapeColorCodes = (colorCodes) => {
  let colorCode = colorCodes.shift();
  let color, mode, r, g, b;

  switch (true) {
    case colorCode == 0:
      return {backgroundColor: null, color: null, decoration: null};

    case colorCode == 1:
      color = parseEscapeColorCodes(colorCodes);
      return Object.assign(color, {decoration: "bold"});

    case (colorCode >= 30 && colorCode < 38):
      color = parseEscapeColorCodes(colorCodes);
      return Object.assign(color, {color: basicColorCodes[colorCode - 30]});

    case (colorCode >= 40 && colorCode < 48):
      color = parseEscapeColorCodes(colorCodes);
      return Object.assign({backgroundColor: basicColorCodes[colorCode - 40]});

    case (colorCode >= 90 && colorCode < 98):
      color = parseEscapeColorCodes(colorCodes);
      return Object.assign(color, {color: basicColorCodes[colorCode - 90], decoration: "bright"});

    case (colorCode >= 100 && colorCode < 108):
      color = parseEscapeColorCodes(colorCodes);
      return Object.assign(color, {backgroundColor: basicColorCodes[colorCode - 100], decoration: "bright"});

    case colorCode == 38:
      mode = colorCodes.shift();

      if (mode == 5) {
        colorCode = colorCodes.shift();
        color = parse256Color(colorCode, "color");
      } else if (mode == 2) {
        [r, g, b, ...colorCodes] = colorCodes;
        color = {color: rgbToHex(r, g, b)};
      }

      return Object.assign(parseEscapeColorCodes(colorCodes), color);

    case colorCode == 48:
      mode = colorCodes.shift();

      if (mode == 5) {
        colorCode = colorCodes.shift();
        color = parse256Color(colorCode, "backgroundColor");
      } else if (mode == 2) {
        [r, g, b, ...colorCodes] = colorCodes;
        color = {backgroundColor: rgbToHex(r, g, b)};
      }

      return Object.assign(parseEscapeColorCodes(colorCodes), color);

    default:
      return {};
  }
};

export const parseEscapeSequence = (sequence) => {
  // taken from Anser, https://github.com/IonicaBizau/anser
  let matches = sequence.match(/^\u001b\[([!\x3c-\x3f]*)([\d;]*)([\x20-\x2c]*[\x40-\x7e])([\s\S]*)/m);

  if (!matches) {
    return new ParseError(sequence);
  }

  if (matches[1] !== "" || matches[3] !== "m") {
    return new ParseError(sequence);
  }

  let codes = matches[2].split(";").map((code) => { return parseInt(code); });
  let options = parseEscapeColorCodes(codes);
  return new EscapeSequence(matches[4], options);
};

export const segmentEscapes = (text) => {
  let segments = text.split("\u001b");

  // insert the escape code back into restSegments
  let [firstSegment, ...restSegments] = segments;
  restSegments = restSegments.map((segment) => { return `\u001b${segment}`; });
  segments = [firstSegment, ...restSegments];

  segments = segments.map((segment) => {
    if (!segment.startsWith("\u001b")) {
      return new EscapeSequence(segment);
    }

    return parseEscapeSequence(segment);
  });

  return segments;
};

let isTextOnly = (segment) => {
  return _.isEqual(Object.keys(segment), ["text"]);
};

let mergeSequences = (currentSequence, appendSequence) => {
  if (currentSequence === null || currentSequence === undefined) {
    return [appendSequence];
  }

  if (currentSequence instanceof ParseError) {
    return [parseEscapeSequence(currentSequence.sequence + appendSequence.text)];
  }

  return [Object.assign(currentSequence, {text: currentSequence.text + appendSequence.text})];
};

export const combineAndParseSegments = (currentSequence, text) => {
  let segments = segmentEscapes(text);

  if (segments.length == 1 && isTextOnly(segments[0])) {
    return mergeSequences(currentSequence, segments[0]);
  }

  let [firstSegment, ...restSegments] = segments;

  switch (true) {
    case isTextOnly(firstSegment):
      return [...mergeSequences(currentSequence, firstSegment), ...restSegments];

    default:
      return [currentSequence, firstSegment, ...restSegments];
  }
};

export const combineAndParse = (currentLine, text) => {
  let lastSegment;
  if (currentLine && currentLine.last()) {
    lastSegment = currentLine.last();
  }

  let segments = combineAndParseSegments(lastSegment, text);

  let currentLineSequences = [];
  if (currentLine) {
    currentLineSequences = currentLine.sequences.slice(0, currentLine.sequences.length - 1);
  }

  return detectLines([...currentLineSequences, ...segments]);
};

export const detectLines = (sequences) => {
  sequences = sequences.map((sequence) => {
    if (sequence instanceof ParseError) {
      return [sequence];
    }

    let lines = sequence.text.split("\n");

    lines = lines.map((line) => {
      let clone = Object.assign(Object.create(Object.getPrototypeOf(sequence)), sequence);
      return Object.assign(clone, {text: line});
    });

    let lastLine = lines.pop();

    lines = lines.map((line) => {
      return Object.assign(line, {text: line.text + "\n"});
    });

    return [...lines, lastLine];
  });

  sequences = _.flatten(sequences);

  // Merge lines together
  let currentLine = [];
  let mergedLines = [];

  sequences.map((sequence) => {
    if (_.last(sequence.text) === "\n") {
      currentLine.push(sequence);
      mergedLines.push(currentLine);
      currentLine = [];
    } else {
      currentLine.push(sequence);
    }
  });

  mergedLines.push(currentLine);
  mergedLines = _.reject(mergedLines, lines => {
    return lines.length == 0;
  });

  return mergedLines.map((sequences) => {
    sequences = sequences.map((sequence, i) => {
      return Object.assign(sequence, {id: i});
    });

    return new Line(sequences);
  });
};
