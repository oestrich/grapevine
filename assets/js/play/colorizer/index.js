import {parseSequences, detectLines} from "./parser";
import {InputSequence} from "./models";

/**
 * Parse new text and combine it with the previous line
 *
 * Merges the new sequences with the last line and detects the resulting lines.
 */
export const parse = (text, currentLine) => {
  let sequences = [];
  if (currentLine) {
    sequences = currentLine.sequences;
  }
  sequences = parseSequences(sequences, text);
  return detectLines(sequences);
};

/**
 * Append text to the current line
 *
 * Returns an array of new lines
 */
export const appendInput = (currentLine, text) => {
  let sequences = [];
  if (currentLine) {
    sequences = currentLine.sequences;
  }
  let lastSequence = sequences.pop();

  if (lastSequence) {
    let input = new InputSequence(text, lastSequence.getOptions());
    return detectLines([...sequences, lastSequence, input]);
  } else {
    let input = new InputSequence(text, {});
    return detectLines([input]);
  }
};
