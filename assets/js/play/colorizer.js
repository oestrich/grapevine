import _ from "underscore";

export class Line {
  constructor(sequences) {
    this.sequences = sequences;
  }

  last() {
    return _.last(this.sequences);
  }
}

class Sequence {
  constructor(opts) {
    if (opts) {
      if (opts.id !== null && opts.id !== undefined) {
        this.id = opts.id;
      }

      if (opts.color) {
        this.color = opts.color;
      }

      if (opts.backgroundColor) {
        this.backgroundColor = opts.backgroundColor;
      }

      if (opts.decorations) {
        this.decorations = opts.decorations;
      }
    }
  }

  getOptions() {
    return {
      color: this.color,
      backgroundColor: this.backgroundColor,
      decorations: this.decorations,
    };
  }
}

export class ParseError extends Sequence {
  constructor(sequence, opts) {
    super(opts);
    this.sequence = sequence;
  }
}

export class EscapeSequence extends Sequence {
  constructor(text, opts) {
    super(opts);
    this.text = text;
  }

  includeDecoration(decoration) {
    return !!this.decorations && this.decorations.includes(decoration);
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
      return {[key]: basicColorCodes[color - 8], decorations: ["bright"]};

    default:
      return {[key]: colorizer256Colors[color]};
  }
};

/**
 * Merge two codes together
 *
 * If the new code is a reset, returns an empty code
 *
 * Decorations will be merged and uniqued
 */
const mergeCodes = (oldCode, newCode) => {
  if (newCode.reset) {
    return newCode;
  }

  let clone = Object.assign(Object.create(Object.getPrototypeOf(oldCode)), oldCode);

  let oldDecorations = (oldCode.decorations || []).slice(0);
  let newDecorations = (newCode.decorations || []).slice(0);
  let decorations = _.uniq(oldDecorations.concat(newDecorations));

  return Object.assign(clone, newCode, {decorations});
};

/**
 * Parse a set of color codes
 *
 * Will recurse through the list to find all codes that it can work on.
 *
 * Handles:
 *  - Reset
 *  - Bold
 *  - Underline
 *  - Basic colors, background, foreground
 *  - 256 colors, background, foreground
 *  - True colors, background, foreground
 */
export const parseEscapeColorCodes = (colorCodes) => {
  let colorCode = colorCodes.shift();
  let color, mode, r, g, b;

  switch (true) {
    case colorCode == 0:
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes({reset: true}, color);

    case colorCode == 1:
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {decorations: ["bold"]});

    case colorCode == 4:
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {decorations: ["underline"]});

    case (colorCode >= 30 && colorCode < 38):
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {color: basicColorCodes[colorCode - 30]});

    case (colorCode >= 40 && colorCode < 48):
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {backgroundColor: basicColorCodes[colorCode - 40]});

    case (colorCode >= 90 && colorCode < 98):
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {color: basicColorCodes[colorCode - 90], decorations: ["bright"]});

    case (colorCode >= 100 && colorCode < 108):
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {backgroundColor: basicColorCodes[colorCode - 100], decorations: ["bright"]});

    case colorCode == 38:
      mode = colorCodes.shift();

      if (mode == 5) {
        colorCode = colorCodes.shift();
        color = parse256Color(colorCode, "color");
      } else if (mode == 2) {
        [r, g, b, ...colorCodes] = colorCodes;
        color = {color: rgbToHex(r, g, b)};
      }

      return mergeCodes(parseEscapeColorCodes(colorCodes), color);

    case colorCode == 48:
      mode = colorCodes.shift();

      if (mode == 5) {
        colorCode = colorCodes.shift();
        color = parse256Color(colorCode, "backgroundColor");
      } else if (mode == 2) {
        [r, g, b, ...colorCodes] = colorCodes;
        color = {backgroundColor: rgbToHex(r, g, b)};
      }

      return mergeCodes(parseEscapeColorCodes(colorCodes), color);

    default:
      return {};
  }
};

/**
 * Picks apart the pieces of the escape code
 *
 * May return a ParseError
 *
 * Merges the current escape sequence with the previous escape sequence
 * to let them build up upon each other.
 */
export const parseEscapeSequence = (sequence, currentOptions) => {
  // taken from Anser, https://github.com/IonicaBizau/anser
  let matches = sequence.match(/^\u001b\[([!\x3c-\x3f]*)([\d;]*)([\x20-\x2c]*[\x40-\x7e])([\s\S]*)/m);

  if (!matches) {
    return new ParseError(sequence, currentOptions);
  }

  if (matches[1] !== "" || matches[3] !== "m") {
    return new ParseError(sequence, currentOptions);
  }

  let codes = matches[2].split(";").map((code) => { return parseInt(code); });
  let options = parseEscapeColorCodes(codes);
  options = mergeCodes(currentOptions, options);
  return new EscapeSequence(matches[4], options);
};

/**
 * Split incoming text into escape segments
 *
 * After splitting, build escape sequences from parsing the sequence. The last
 * parsed sequence will flow through parsing.
 */
export const segmentEscapes = (text, options) => {
  let segments = text.split("\u001b");

  // insert the escape code back into restSegments
  let [firstSegment, ...restSegments] = segments;
  restSegments = restSegments.map((segment) => { return `\u001b${segment}`; });
  segments = [firstSegment, ...restSegments];

  segments = segments.map((segment) => {
    if (!segment.startsWith("\u001b")) {
      return new EscapeSequence(segment);
    }

    segment = parseEscapeSequence(segment, options);
    if (!(segment instanceof ParseError)) {
      options = segment.getOptions();
    }
    return segment;
  });

  return segments;
};

/**
 * Check if a segment contains only text
 */
let isTextOnly = (segment) => {
  return _.isEqual(Object.keys(segment), ["text"]);
};

/**
 * Merge two sequences together
 *
 * Handles ParseErrors by joining the new text onto the previous sequence and re-parsing
 */
let mergeSequences = (currentSequence, appendSequence) => {
  if (currentSequence === null || currentSequence === undefined) {
    return [appendSequence];
  }

  if (currentSequence instanceof ParseError) {
    return [parseEscapeSequence(currentSequence.sequence + appendSequence.text, currentSequence.getOptions())];
  }

  if (appendSequence instanceof ParseError) {
    return [currentSequence, appendSequence];
  }

  return [Object.assign(currentSequence, {text: currentSequence.text + appendSequence.text})];
};

/**
 * Parses new text into sequences
 *
 * Merges the past sequences with the new sequences. Handles parsing errors
 * with new text that fixes the parse error.
 */
export const combineAndParseSegments = (currentSequences, text) => {
  let currentSequence;
  if (_.last(currentSequences)) {
    currentSequence = currentSequences.pop();
  }

  if (currentSequence instanceof ParseError) {
    text = currentSequence.sequence + text;
    currentSequence = new EscapeSequence("", currentSequence.getOptions());
  }

  let options = {};
  if (currentSequence && !(currentSequence instanceof ParseError)) {
    options = currentSequence.getOptions();
  }

  let segments = segmentEscapes(text, options);

  let [firstSegment, ...restSegments] = segments;

  switch (true) {
    case isTextOnly(firstSegment):
      return [...currentSequences, ...mergeSequences(currentSequence, firstSegment), ...restSegments];

    default:
      return [...currentSequences, currentSequence, firstSegment, ...restSegments];
  }
};

/**
 * Parse new text and combine it with the previous line
 *
 * Merges the new sequences with the last line and detects the resulting lines.
 */
export const combineAndParse = (currentLine, text) => {
  let sequences = [];
  if (currentLine) {
    sequences = currentLine.sequences;
  }

  sequences = combineAndParseSegments(sequences, text);
  return detectLines(sequences);
};

/**
 * Split sequences apart and group by new lines
 *
 * Returns `Line`s with all sequences contained within. Each line ends
 * with a `\n`.
 */
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
  let lastSequence = sequences.pop();
  if (!(lastSequence instanceof ParseError)) {
    sequences = _.reject(sequences, (sequence) => {
      return sequence.text === "";
    });
  }
  sequences = [...sequences, lastSequence];

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
