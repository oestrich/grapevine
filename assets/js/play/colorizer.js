import {parseSequences, detectLines} from "./colorizer/parser";
import {InputSequence} from "./colorizer/models";

/**
 * Parse new text and combine it with the previous line
 *
 * Merges the new sequences with the last line and detects the resulting lines.
 */
export const parse = (currentLine, text) => {
  let sequences = [];
  if (currentLine) {
    sequences = currentLine.sequences;
  }

  sequences = parseSequences(sequences, text);
  return detectLines(sequences);
};

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
