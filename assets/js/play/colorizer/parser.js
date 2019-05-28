import _ from "underscore";
import {Line, EscapeSequence, ParseError} from "./models";
import {basicColorCodes, rgbToHex, parse256Color} from "./colors";

/**
 * Parses new text into sequences
 *
 * Merges the past sequences with the new sequences. Handles parsing errors
 * with new text that fixes the parse error.
 */
export const parseSequences = (currentSequences, text) => {
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

  let sequences = splitByEscapeSequence(text, options);

  let [firstSegment, ...restSegments] = sequences;

  switch (true) {
    case isTextOnly(firstSegment):
      return [...currentSequences, ...mergeSequences(currentSequence, firstSegment), ...restSegments];

    default:
      return [...currentSequences, currentSequence, firstSegment, ...restSegments];
  }
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
  sequences = _.reject(sequences, (sequence) => {
    return sequence.text === "";
  });
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
  const unsupportedCodes = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "S", "T", "mf", "i", "n", "u", "s", "h", "l"];

  if (!matches) {
    return new ParseError(sequence, currentOptions);
  }

  if (unsupportedCodes.includes(matches[3])) {
    return new EscapeSequence(matches[4], currentOptions);
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
 * Split incoming text into escape sequences
 *
 * After splitting, build escape sequences from parsing the sequence. The last
 * parsed sequence will flow through parsing.
 */
export const splitByEscapeSequence = (text, options) => {
  let sequences = text.split("\u001b");

  // insert the escape code back into restSegments
  let [firstSegment, ...restSegments] = sequences;
  restSegments = restSegments.map((sequence) => { return `\u001b${sequence}`; });
  sequences = [firstSegment, ...restSegments];

  sequences = sequences.map((sequence) => {
    if (!sequence.startsWith("\u001b")) {
      return new EscapeSequence(sequence);
    }

    sequence = parseEscapeSequence(sequence, options);
    if (!(sequence instanceof ParseError)) {
      options = sequence.getOptions();
    }
    return sequence;
  });

  return sequences;
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

  if (newCode.reverse) {
    return Object.assign(clone, newCode, {decorations, color: clone.backgroundColor, backgroundColor: clone.color});
  } else {
    return Object.assign(clone, newCode, {decorations});
  }
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
const parseEscapeColorCodes = (colorCodes) => {
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

    case colorCode == 5 || colorCode == 6:
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {decorations: ["blink"]});

    case colorCode == 7:
      color = parseEscapeColorCodes(colorCodes);
      return mergeCodes(color, {reverse: true});

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
 * Check if a sequence contains only text
 */
let isTextOnly = (sequence) => {
  return _.isEqual(Object.keys(sequence), ["text"]);
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
